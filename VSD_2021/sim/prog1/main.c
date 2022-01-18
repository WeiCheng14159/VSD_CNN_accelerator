unsigned int *copy_addr; // = &_test_start;
unsigned int copy_count = 0;
const unsigned int sensor_size = 64;
volatile unsigned int *sensor_addr = (int *) 0x10000000;
extern void setDMA(unsigned int *source, unsigned int *dest, unsigned int quantity);
/*****************************************************************
 * Function: void copy()                                         *
 * Description: Part of interrupt service routine (ISR).         *
 *              Copy data from sensor controller to data memory. *
 *****************************************************************/
void copy () {
  int i;
  for (i = 0; i < sensor_size; i++) { // Copy data from sensor controller to DM
    *(copy_addr + i) = sensor_addr[i];
  }
  // asm("csrsi mstatus, 0x8"); // MIE of mstatus
  // setDMA(sensor_addr, copy_addr, sensor_size);
  copy_addr += sensor_size; // Update copy address
  asm("addi t3, x0, 1");
  copy_count++;    // Increase copy count
  sensor_addr[0x80] = 1; // Enable sctrl_clear
  sensor_addr[0x80] = 0; // Disable sctrl_clear
  if (copy_count == 4) {
    asm("li t6, 0x80");
    asm("csrc mstatus, t6"); // Disable MPIE of mstatus
  }
  return;
}

/*****************************************************************
 * Function: void Quick Sort                                     *
 * Description: Sorting data                                     *
 *****************************************************************/
void swap (int* a, int* b) {
    int temp = *a;
    *a = *b; 
    *b = temp;
}
// return partition index
int partition(int array[], int low, int high) {
    int pivot = array[high];
    int i = low - 1;
    for (int j = low; j <= high - 1; j++) {
        if (array[j] < pivot) {
            i++;
            swap(&array[i], &array[j]);
        }
    }
    swap(&array[i + 1], &array[high]);
    return (i+1);
}

void QuickSort(int array[], int low, int high) {
    if (low < high) {
        int partition_idx = partition(array, low, high);
        QuickSort(array, low, partition_idx - 1);
        QuickSort(array, partition_idx + 1, high);
    }
}


int main(void) {
  extern unsigned int _test_start;
  int *sort_addr = &_test_start;
  int sort_count = 0;
  copy_addr = &_test_start;

  // Enable Global Interrupt
  // asm("csrsi mstatus, 0x8"); // MIE of mstatus

  // // Enable Local Interrupt
  // asm("li t6, 0x800");
  // asm("csrs mie, t6"); // MEIE of mie 

  // Enable Sensor Controller
  sensor_addr[0x40] = 1; // Enable sctrl_en

  while (sort_count != 4) {
    if (sort_count == copy_count) { // Sensor controller isn't ready
      // Wait for interrupt of sensor controller
      asm("wfi");
      // Because there is only one interrupt source, we don't need to poll interrupt source
    }

    // Start sorting
    // sort(sort_addr, sensor_size);
    QuickSort(sort_addr, 0, sensor_size - 1);
    sort_addr += sensor_size;
    sort_count++;
  }

  return 0;
}
