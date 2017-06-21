import math
import time

if __name__ == '__main__':
    while True:
        start = time.time()
        math.factorial(50000)
        end = time.time()

        print end - start

        time.sleep(1)
