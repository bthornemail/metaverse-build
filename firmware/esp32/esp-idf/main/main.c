// Capability: TCP bus subscriber (projection endpoint)
// Authority: AuthorityGate (upstream)
// Justification: metaverse-build/profiles/kernel-v1/PROFILE.md
// Inputs: TCP bus newline-delimited messages
// Outputs: Serial log of payload
// Trace: no
// Halt-On-Violation: yes (upstream only)

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/param.h>
#include <sys/socket.h>
#include <netdb.h>

#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/event_groups.h"

#include "esp_event.h"
#include "esp_log.h"
#include "esp_system.h"
#include "esp_wifi.h"
#include "nvs_flash.h"

#define WIFI_CONNECTED_BIT BIT0

static const char *TAG = "metaverse-esp32";
static EventGroupHandle_t s_wifi_event_group;

static void wifi_event_handler(void *arg, esp_event_base_t event_base, int32_t event_id, void *event_data) {
    if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_START) {
        esp_wifi_connect();
    } else if (event_base == WIFI_EVENT && event_id == WIFI_EVENT_STA_DISCONNECTED) {
        esp_wifi_connect();
        ESP_LOGW(TAG, "Wi-Fi disconnected, retrying...");
    } else if (event_base == IP_EVENT && event_id == IP_EVENT_STA_GOT_IP) {
        xEventGroupSetBits(s_wifi_event_group, WIFI_CONNECTED_BIT);
    }
}

static void wifi_init_sta(void) {
    s_wifi_event_group = xEventGroupCreate();
    ESP_ERROR_CHECK(esp_netif_init());
    ESP_ERROR_CHECK(esp_event_loop_create_default());
    esp_netif_create_default_wifi_sta();

    wifi_init_config_t cfg = WIFI_INIT_CONFIG_DEFAULT();
    ESP_ERROR_CHECK(esp_wifi_init(&cfg));

    ESP_ERROR_CHECK(esp_event_handler_instance_register(WIFI_EVENT,
                                                        ESP_EVENT_ANY_ID,
                                                        &wifi_event_handler,
                                                        NULL,
                                                        NULL));
    ESP_ERROR_CHECK(esp_event_handler_instance_register(IP_EVENT,
                                                        IP_EVENT_STA_GOT_IP,
                                                        &wifi_event_handler,
                                                        NULL,
                                                        NULL));

    wifi_config_t wifi_config = {
        .sta = {
            .ssid = CONFIG_ESP_WIFI_SSID,
            .password = CONFIG_ESP_WIFI_PASSWORD,
            .threshold.authmode = WIFI_AUTH_WPA2_PSK,
        },
    };

    ESP_ERROR_CHECK(esp_wifi_set_mode(WIFI_MODE_STA));
    ESP_ERROR_CHECK(esp_wifi_set_config(WIFI_IF_STA, &wifi_config));
    ESP_ERROR_CHECK(esp_wifi_start());

    ESP_LOGI(TAG, "Wi-Fi init done, connecting...");
}

static void tcp_bus_task(void *pvParameters) {
    char rx_buffer[256];
    char line_buffer[256];
    int line_len = 0;

    while (1) {
        struct addrinfo hints = {
            .ai_family = AF_INET,
            .ai_socktype = SOCK_STREAM
        };
        struct addrinfo *res = NULL;
        int err = getaddrinfo(CONFIG_BUS_HOST, CONFIG_BUS_PORT, &hints, &res);
        if (err != 0 || res == NULL) {
            ESP_LOGE(TAG, "getaddrinfo failed: %d", err);
            vTaskDelay(pdMS_TO_TICKS(2000));
            continue;
        }

        int sock = socket(res->ai_family, res->ai_socktype, 0);
        if (sock < 0) {
            ESP_LOGE(TAG, "Unable to create socket");
            freeaddrinfo(res);
            vTaskDelay(pdMS_TO_TICKS(2000));
            continue;
        }

        ESP_LOGI(TAG, "Connecting to TCP bus %s:%s", CONFIG_BUS_HOST, CONFIG_BUS_PORT);
        if (connect(sock, res->ai_addr, res->ai_addrlen) != 0) {
            ESP_LOGE(TAG, "Socket connect failed");
            close(sock);
            freeaddrinfo(res);
            vTaskDelay(pdMS_TO_TICKS(2000));
            continue;
        }
        freeaddrinfo(res);
        ESP_LOGI(TAG, "Connected to TCP bus");

        while (1) {
            int len = recv(sock, rx_buffer, sizeof(rx_buffer) - 1, 0);
            if (len < 0) {
                ESP_LOGE(TAG, "recv failed");
                break;
            } else if (len == 0) {
                ESP_LOGW(TAG, "connection closed");
                break;
            }
            for (int i = 0; i < len; i++) {
                char c = rx_buffer[i];
                if (c == '\n' || line_len >= (int)sizeof(line_buffer) - 1) {
                    line_buffer[line_len] = '\0';
                    if (line_len > 0) {
                        printf("BUS %s\n", line_buffer);
                        fflush(stdout);
                    }
                    line_len = 0;
                } else {
                    line_buffer[line_len++] = c;
                }
            }
        }

        close(sock);
        vTaskDelay(pdMS_TO_TICKS(1000));
    }
}

void app_main(void) {
    ESP_ERROR_CHECK(nvs_flash_init());

    wifi_init_sta();

    xEventGroupWaitBits(s_wifi_event_group, WIFI_CONNECTED_BIT, pdFALSE, pdTRUE, portMAX_DELAY);
    ESP_LOGI(TAG, "Wi-Fi connected");

    xTaskCreate(tcp_bus_task, "tcp_bus_task", 4096, NULL, 5, NULL);
}
