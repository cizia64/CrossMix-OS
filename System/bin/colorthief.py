import sys
from modern_colorthief import get_color

path = sys.argv[1]

print("%02X%02X%02X" % get_color(path, 8))
