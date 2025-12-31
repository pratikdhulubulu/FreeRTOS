#include "FreeRTOS.h"
#include "task.h"
#include "stm32f446_hw.h"

static void vLedTask(void *ptr_param);
static void vCounterTask(void *ptr_param);

volatile uint32_t g_counter = 0;

int main(void)
{
    // Enable GPIOA clock
    RCC_AHB1ENR |= (1U << 0);

    // Configure PA5 as output
    GPIOA_MODER &= ~(3U << 10);
    GPIOA_MODER |=  (1U << 10);

    // Create LED task - higher priority
    xTaskCreate(vLedTask, "LED", 128, 0, 1, 0);

    // Create Counter task - lower priority
    xTaskCreate(vCounterTask, "Counter", 256, 0, 1, 0);

    vTaskStartScheduler();

    for (;;);
}

static void vLedTask(void *ptr_param)
{
    (void)ptr_param;

    for (;;)
    {
        GPIOA_ODR ^= (1U << 5);        
        vTaskDelay(pdMS_TO_TICKS(100));
    }
}

static void vCounterTask(void *ptr_param)
{
    (void)ptr_param;

    for (;;)
    {
        g_counter++;                   
        vTaskDelay(pdMS_TO_TICKS(500)); 
    }
}
