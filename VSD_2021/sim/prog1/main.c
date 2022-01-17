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
 * Function: void sort(int *, unsigned int)                      *
 * Description: Sorting data                                     *
 *****************************************************************/
void sort(int *array, unsigned int size) {
  int i, j;
  int temp;
  for (i = 0; i < size - 1; i++) {
    for (j = i + 1; j < size; j++) {
      if (array[i] > array[j]) {
        temp = array[i];
        array[i] = array[j];
        array[j] = temp;
      }
    }
  }
  return;
}

/*****************************************************************
 * Function: void Merge Sort                                     *
 * Description: Sorting data                                     *
 *****************************************************************/
void Merge(int array[], int l, int m, int r) {
    int i, j, k;
    int n1 = m - l + 1;
    int n2 = r - m;
    // temp array
    int L[n1], R[n2];
    // copy to temp array
    for (i = 0; i < n1; i++)
        L[i] = array[l + i];
    for (j = 0; j < n2; j++)
        R[j] = array[m + 1 + j];
    i = 0; // initial index of first subarray
    j = 0; // initial index of second subarray
    k = l; // initial index of merged subarray
    while (i < n1 && j < n2) {
        if (L[i] <= R[j]) {
            array[k] = L[i];
            i++;
        }
        else {
            array[k] = R[j];
            j++;
        }
        k++;
    }
    // copy remaining elements of L[]
    while (i < n1) {
        array[k] = L[i];
        k++;
        i++;
    }
    // copy remaining elements of R[]
    while (j < n2) {
        array[k] = R[j];
        k++;
        j++;
    }
    return;
}

void MergeSort(int array[], unsigned int l, unsigned int r) {
    if (l < r) {
        int m = l + (r - l) / 2;
        MergeSort(array, l, m);
        MergeSort(array, m + 1, r);
        Merge(array, l, m, r);
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
  asm("csrsi mstatus, 0x8"); // MIE of mstatus

  // Enable Local Interrupt
  asm("li t6, 0x800");
  asm("csrs mie, t6"); // MEIE of mie 

  // Enable Sensor Controller
  sensor_addr[0x40] = 1; // Enable sctrl_en

  while (sort_count != 4) {
    if (sort_count == copy_count) { // Sensor controller isn't ready
      // Wait for interrupt of sensor controller
      asm("wfi");
      // Because there is only one interrupt source, we don't need to poll interrupt source
    }

    // Start sorting
    //sort(sort_addr, sensor_size);
    //MergeSort(sort_addr, 0, sensor_size - 1);
    QuickSort(sort_addr, 0, sensor_size - 1);
    sort_addr += sensor_size;
    sort_count++;
  }

  return 0;
}
