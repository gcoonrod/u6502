/**
 * @file main.cpp
 * @brief Arduino Mega2560 Sketch to monitor the address, data, and control lines of the 6502 bus.
 *
 * Debug Monitor for 6502 Bus (Mini 6502 SBC rev 1.0)
 *
 * This sketch monitors the address, data, and control lines of the 6502 bus. During setup it will hold
 * the 6502 in reset, configure the address, data, and control lines as inputs, and then release the reset
 * and begin monitoring the bus. The sketch will print the address, data, and control lines to the serial.
 */

#include <Arduino.h>

// General Definitions
#define BAUD_RATE 115200
#define WAIT_FOR_SERIAL 1
//#define INTERCEPT

// Control Line Pin Definitions
#define CLK_PIN 2
#define RWB_PIN 3
#define RESB_PIN 18

// Address Line Pin Definitions (A0-A15 = 22-52 even)
const uint8_t ADDR_BUS[] = {22, 24, 26, 28, 30, 32, 34, 36, 38, 40, 42, 44, 46, 48, 50, 52};

// Data Line Pin Definitions (D0-D7 = 23-37 odd)
const uint8_t DATA_BUS[] = {23, 25, 27, 29, 31, 33, 35, 37};

// Global Variables
volatile uint16_t clk_count = 0;
volatile uint8_t new_clk_cycle = 0;
volatile uint8_t clk_state = 0;
volatile uint8_t rwb_state = 0;
volatile uint8_t resb_state = 0;
volatile uint16_t addr = 0;
volatile uint8_t data = 0;
volatile uint8_t data_bus_dir = INPUT;

void clk_change_isr(void);
void clk_rise_isr(void);
void clk_fall_isr(void);
void resb_change_isr(void);
void print_word_bin(uint16_t word);
void print_byte_bin(uint8_t byte);
void print_word_hex(uint16_t word);
void print_byte_hex(uint8_t byte);

//

void setup(void)
{

  // Disable Interrupts
  noInterrupts();

  // Configure Reset Pin first and pull low to hold 6502 in reset
  // pinMode(RESB_PIN, OUTPUT);
  // digitalWrite(RESB_PIN, LOW);

  // Configure Control Lines
  pinMode(CLK_PIN, INPUT);
  pinMode(RWB_PIN, INPUT);
  pinMode(RESB_PIN, INPUT_PULLUP);

  // Configure Address Lines
  for (uint8_t i = 0; i < sizeof(ADDR_BUS); i++)
  {
    pinMode(ADDR_BUS[i], INPUT);
  }

  // Configure Data Lines
  for (uint8_t i = 0; i < sizeof(DATA_BUS); i++)
  {
    pinMode(DATA_BUS[i], data_bus_dir);
  }

  // Start the Serial Monitor
  Serial.begin(BAUD_RATE);
  if (WAIT_FOR_SERIAL)
  {
    while (!Serial)
    {
      ; // Wait for Serial Monitor to connect
    }
  }

  // Setup Complete
  Serial.println(F("Debug Monitor for 6502 Bus (Mini 6502 SBC rev 1.0)"));
  Serial.println(F("Releasing Reset..."));

  // Release Reset
  // digitalWrite(RESB_PIN, HIGH);
  // pinMode(RESB_PIN, INPUT_PULLUP);

  // Attach Interrupts
  attachInterrupt(digitalPinToInterrupt(CLK_PIN), clk_change_isr, CHANGE);
  attachInterrupt(digitalPinToInterrupt(RESB_PIN), resb_change_isr, CHANGE);

  // Enable Interrupts
  interrupts();
}

void loop(void)
{

  // If in reset, do nothing
  if (resb_state == LOW)
  {
    Serial.println("RESET");
    clk_count = 0;
    delay(100);
    return;
  }

  // If we've reached 65535 clock cycles, reset the counter
  if (clk_count == 65535)
  {
    Serial.println("PC Rollover");
    clk_count = 0;
  }
}

// ISR Handlers

/**
 * The 65C02 clock cycle starts with a falling edge of the clock signal. The address and RWB will be valid on the
 * bus after 30ns max (tADS). TODO figure out all the timings. For now we'll be slow enough that it doesn't matter.
 */
void clk_change_isr(void)
{
  noInterrupts();
  // Read the clock state first
  clk_state = digitalRead(CLK_PIN);
  switch (clk_state)
  {
  case LOW:
    clk_fall_isr();
    break;
  case HIGH:
    clk_rise_isr();
    break;
  }
  interrupts();
}

void clk_fall_isr(void)
{
  new_clk_cycle = 1;
  // Read the Address Bus and Control Line states
  addr = 0;
  for (uint8_t i = 0; i < sizeof(ADDR_BUS); i++)
  {
    addr |= (digitalRead(ADDR_BUS[i]) << i);
  }
  rwb_state = digitalRead(RWB_PIN);

  // If not in reset, set the data bus direction based on the RWB state
  if (resb_state == HIGH)
  {
    if (rwb_state == HIGH)
    {
      data_bus_dir = OUTPUT;
    }
    else
    {
      data_bus_dir = INPUT;
    }
  }
}

void clk_rise_isr(void)
{
  clk_state = HIGH;
  // Read the Data Bus state (we don't do any writing yet)
  if (new_clk_cycle == 1)
  {

    if (resb_state == HIGH)
    {
#ifdef INTERCEPT
      if (data_bus_dir == INPUT)
      {
        data = 0;
        for (uint8_t i = 0; i < sizeof(DATA_BUS); i++)
        {
          pinMode(DATA_BUS[i], INPUT);
          data |= (digitalRead(DATA_BUS[i]) << i);
        }
      }
      else
      {
        // Intercept the any read from $FFFC, $FFFD
        // and set the PC to $0000
        if (addr == 0xFFFC || addr == 0xFFFD)
        {
          // Set the data bus to ouput and write $00
          data = 0x00;
          for (uint8_t i = 0; i < sizeof(DATA_BUS); i++)
          {
            pinMode(DATA_BUS[i], OUTPUT);
            digitalWrite(DATA_BUS[i], LOW);
          }
        }
        else
        {
          // Set the data bus to output and write $EA (NOP)
          data = 0xEA;
          for (uint8_t i = 0; i < sizeof(DATA_BUS); i++)
          {
            pinMode(DATA_BUS[i], OUTPUT);
            digitalWrite(DATA_BUS[i], (data >> i) & 0x01);
          }
        }
      }
#else
      data = 0;
      for (uint8_t i = 0; i < sizeof(DATA_BUS); i++)
      {
        data |= (digitalRead(DATA_BUS[i]) << i);
      }
#endif

      // Print the address, data, and control lines
      // Always pad the address and PC to 16 bits, and the data to 8 bits
      Serial.print(F("PC: "));
      print_word_hex(clk_count);
      Serial.print(F(" ADDR: "));
      print_word_bin(addr);
      Serial.print(F(" "));
      print_word_hex(addr);
      Serial.print(F(" DATA: "));
      print_byte_bin(data);
      Serial.print(F(" "));
      print_byte_hex(data);
      Serial.println(rwb_state ? F(" r") : F(" W"));
    }

    // Clear the new_clk_cycle flag
    new_clk_cycle = 0;
    clk_count++;
  }
}

void resb_change_isr(void)
{
  resb_state = digitalRead(RESB_PIN);
}

void print_word_bin(uint16_t word)
{
  // Convert the word (two bytes) to a 16 charater string representing the binary value and print
  char word_str[17];
  for (uint8_t i = 0; i < 16; i++)
  {
    word_str[i] = (word & (1 << (15 - i))) ? '1' : '0';
  }
  word_str[16] = '\0';
  Serial.print(word_str);
}

void print_word_hex(uint16_t word)
{
  // Convert the word (two bytes) to a 4 charater string representing the hex value and print
  char word_str[5];
  sprintf(word_str, "%04X", word);
  Serial.print(word_str);
}

void print_byte_bin(uint8_t byte)
{
  // Convert the byte (one byte) to an 8 charater string representing the binary value and print
  char byte_str[9];
  for (uint8_t i = 0; i < 8; i++)
  {
    byte_str[i] = (byte & (1 << (7 - i))) ? '1' : '0';
  }
  byte_str[8] = '\0';
  Serial.print(byte_str);
}

void print_byte_hex(uint8_t byte)
{
  // Convert the byte (one byte) to a 2 charater string representing the hex value and print
  char byte_str[3];
  sprintf(byte_str, "%02X", byte);
  Serial.print(byte_str);
}