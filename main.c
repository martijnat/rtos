#include "FreeRTOS.h"
#include "semphr.h"
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



SemaphoreHandle_t global_mtx; // Mutex handle
#define data_size 80
static char data[data_size+3];

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

// printing task
void print_task(void *pvParameters) {
    while (1) {
      if (xSemaphoreTake(global_mtx, portMAX_DELAY) == pdTRUE) {
        uart_puts(data);
        xSemaphoreGive(global_mtx);
        vTaskDelay(pdMS_TO_TICKS(1000)); // Delay 1 second
      }
    }
}

void update_task(void *pvParameters) {
  /* spooky non-mutex data preparation. */
  for(int i=0;i<data_size;i++)
    data[i]=' ';
  data[0]='#';                /* set one byte to one for interesting behaviour */

  data[data_size  ]='\r'; // set last bytes to allow printing
  data[data_size+1]='\n';
  data[data_size+2]='\0';

  char newdata[data_size];
  while (1) {
    if (xSemaphoreTake(global_mtx, portMAX_DELAY) == pdTRUE) {
      for(int i=0;i<data_size;i++) {
          newdata[i]=0;
          if(data[(data_size+i+1)%data_size]==' ') newdata[i]^=1;
          if(data[(data_size+i-1)%data_size]==' ') newdata[i]^=1;
        }
        for(int i=0;i<data_size;i++)
          data[i]=(newdata[i]==1)?'#':' ';

      xSemaphoreGive(global_mtx);
      vTaskDelay(pdMS_TO_TICKS(1000)); // Delay 1 second
    }

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

    global_mtx = xSemaphoreCreateMutex(); // Create the mutex
    if (global_mtx == NULL) {
          uart_puts("Could not initialize mutex\r\n");
    }

    // Create the printing task
    xTaskCreate(
        print_task,           // Task function
        "PrintToUART",          // Task name
        configMINIMAL_STACK_SIZE * 2,  // Stack size
        NULL,                 // Parameters
        tskIDLE_PRIORITY + 1, // Priority
        NULL                  // Task handle
    );

    // Create the update task
    xTaskCreate(
        update_task,           // Task function
        "UpdateData",          // Task name
        configMINIMAL_STACK_SIZE * 2,  // Stack size
        NULL,                 // Parameters
        tskIDLE_PRIORITY + 2, // Priority
        NULL                  // Task handle
    );

    uart_puts("Starting FreeRTOS scheduler...\r\n");

    // Start the FreeRTOS scheduler
    vTaskStartScheduler();

    // Should never reach here
    uart_puts("Scheduler failed to start!\r\n");
    for (;;);
}
