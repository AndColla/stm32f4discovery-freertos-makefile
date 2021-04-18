#include "FreeRTOS.h"
#include "task.h"

#include <libopencm3/stm32/rcc.h>
#include <libopencm3/stm32/gpio.h>

static void task1(void *args __attribute((unused))) {
	for (;;) {
		gpio_toggle(GPIOD, GPIO12);
		vTaskDelay(pdMS_TO_TICKS(500));
	}
}

static void task2(void *args __attribute((unused))) {
	for (;;) {
		gpio_toggle(GPIOD, GPIO13);
		vTaskDelay(pdMS_TO_TICKS(800));
	}
}

int main(void)
{
	rcc_clock_setup_pll(&rcc_hse_8mhz_3v3[RCC_CLOCK_3V3_168MHZ]);

    rcc_periph_clock_enable(RCC_GPIOD);
    gpio_mode_setup(GPIOD, GPIO_MODE_OUTPUT, GPIO_PUPD_NONE, GPIO12 | GPIO13);

    xTaskCreate(task1,"LED1",100,NULL,configMAX_PRIORITIES-1,NULL);
	xTaskCreate(task2,"LED2",100,NULL,configMAX_PRIORITIES-1,NULL);
	vTaskStartScheduler();
	for (;;);

	return 0;
}
