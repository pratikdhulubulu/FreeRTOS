#ifndef STM32F446_HW_H
#define STM32F446_HW_H

#include <stdint.h>

#define RCC_AHB1ENR   (*(volatile uint32_t *)0x40023830U)
#define GPIOA_MODER   (*(volatile uint32_t *)0x40020000U)
#define GPIOA_ODR     (*(volatile uint32_t *)0x40020014U)

#endif
