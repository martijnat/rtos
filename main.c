#include "FreeRTOS.h"
#include "task.h"
#include <stdint.h>

// System Control registers for LM3S6965
#define SYSCTL_BASE     0x400FE000
#define SYSCTL_RCC      (*(volatile uint32_t*)(SYSCTL_BASE + 0x060))
#define SYSCTL_RCC2     (*(volatile uint32_t*)(SYSCTL_BASE + 0x070))

// UART base address for Stellaris LM3S6965EVB
#define UART0_BASE 0x4000C000
#define UART_DR    (*(volatile uint32_t*)(UART0_BASE + 0x000))
#define UART_FR    (*(volatile uint32_t*)(UART0_BASE + 0x018))

// System initialization
void SystemInit(void) {
    // Use internal oscillator, disable PLL for simplicity
    SYSCTL_RCC = 0x00000000;  // Use main oscillator, no PLL
    SYSCTL_RCC2 = 0x00000000; // Disable RCC2 override
}

// Simple UART write function
void uart_putc(char c) {
    // Wait for transmit FIFO to have space
    while (UART_FR & (1 << 5));
    UART_DR = c;
}

void uart_puts(const char* str) {
    while (*str) {
        uart_putc(*str++);
    }
}

// Hello World task
void hello_task(void *pvParameters) {
    int counter = 0;

    uart_puts("FreeRTOS Hello World started!\r\n");

    while (1) {
        uart_puts("Hello World from FreeRTOS! Counter: ");

        // Simple integer to string conversion
        char num_str[16];
        int temp = counter;
        int i = 0;

        if (temp == 0) {
            num_str[i++] = '0';
        } else {
            char temp_str[16];
            int j = 0;
            while (temp > 0) {
                temp_str[j++] = '0' + (temp % 10);
                temp /= 10;
            }
            // Reverse the string
            for (int k = j - 1; k >= 0; k--) {
                num_str[i++] = temp_str[k];
            }
        }
        num_str[i] = '\0';

        uart_puts(num_str);
        uart_puts("\r\n");

        counter++;
        vTaskDelay(pdMS_TO_TICKS(1000)); // Delay 1 second
    }
}

// FreeRTOS hook functions
void vApplicationMallocFailedHook(void) {
    uart_puts("Malloc failed!\r\n");
    for (;;);
}

void vApplicationIdleHook(void) {
    // Idle hook - can be empty
}

void vApplicationStackOverflowHook(TaskHandle_t xTask, char *pcTaskName) {
    uart_puts("Stack overflow in task: ");
    uart_puts(pcTaskName);
    uart_puts("\r\n");
    for (;;);
}

void vApplicationTickHook(void) {
    // Tick hook - can be empty
}

int main(void) {
    // Initialize the system
    SystemInit();

    uart_puts("System starting...\r\n");

    // Create the hello world task
    xTaskCreate(
        hello_task,           // Task function
        "HelloTask",          // Task name
        configMINIMAL_STACK_SIZE * 2,  // Stack size
        NULL,                 // Parameters
        tskIDLE_PRIORITY + 1, // Priority
        NULL                  // Task handle
    );

    uart_puts("Starting FreeRTOS scheduler...\r\n");

    // Start the FreeRTOS scheduler
    vTaskStartScheduler();

    // Should never reach here
    uart_puts("Scheduler failed to start!\r\n");
    for (;;);
}
