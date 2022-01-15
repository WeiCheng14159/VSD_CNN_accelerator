int mul(int x, int y) {
	int ret = 0;
	int sign = 1;
	if (y >> 31) {
		sign = -sign;
		y = -y;
	}
	if (x >> 31) {
		sign = -sign;
		x = -x;
	}
	while (y) {
		if (y & 1)
			ret += x;
		x <<= 1;
		y >>= 1;
	}
	if (sign < 0)
		return -ret;
	return ret;
}

int main(void) {
	extern int array_size_i;
	extern int array_size_j;
	extern int array_size_k;
	extern short array_addr;
	extern int _test_start;

	int idx  = 0, idxA = 0, idxB = 0;
	int start_B = 0;
	int tmp = 0;
	int i = 0, j = 0, k = 0;
	start_B = mul(array_size_i, array_size_k);

	for (i = 0; i < array_size_i; i++) {
		for (j = 0; j < array_size_j; j++) {
			for (k = 0; k<array_size_k; k++) {
				idxA = mul(i, array_size_k) + k;
				idxB = start_B + mul(k, array_size_j) + j;
				tmp += mul((&array_addr)[idxA], (&array_addr)[idxB]);
      		}
		(&_test_start)[idx++] = tmp;
		tmp = 0;
		}
	}
	return 0;
}
