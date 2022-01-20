import sys


class FileReader:
    def __init__(self, filename):
        self.filename = filename

    def open(self):
        print("Reading file ", self.filename)
        try:
            self.file = open(self.filename, 'r')
        except OSError:
            print("Cannot open file ", self.filename)
            sys.exit(-1)
        return self.file

    def get_filename(self):
        return self.filename

    def close(self):
        if hasattr(self, 'file'):
            self.file.close()
            self.__del__()


class FileWriter:
    def __init__(self, filename):
        self.filename = filename

    def open(self):
        print("Writing to file ", self.filename)
        try:
            self.file = open(self.filename, 'wb')
        except OSError:
            print("Cannot open file ", self.filename)
            sys.exit(-1)
        return self.file

    def get_filename(self):
        return self.filename

    def close(self):
        if hasattr(self, 'file'):
            self.file.close()
            self.__del__()

if __name__ == "__main__":

    BYTE_ZERO = "00"

    # Convert In8.hex
    ifname = "./In8.hex"
    ifname_prefix = ifname.split(".hex")[0]
    ofname = ifname_prefix+".dat"
    rf = FileReader(ifname).open()
    wf = FileWriter(ofname).open()
    lines = rf.readlines()
    for l in lines:
        line = l.rstrip("\n")
        wb = bytearray.fromhex(BYTE_ZERO + BYTE_ZERO + BYTE_ZERO + line)
        wb.reverse()
        wf.write(wb)
    rf.close()
    wf.close()

    # Convert param.hex
    ifname = "./param.hex"
    ifname_prefix = ifname.split(".hex")[0]
    ofname = ifname_prefix+".dat"
    rf = FileReader(ifname).open()
    wf = FileWriter(ofname).open()
    lines = rf.readlines()
    for l in lines:
        line = l.rstrip("\n")
        wb = bytearray.fromhex(line)
        wb.reverse()
        wf.write(wb)
    rf.close()
    wf.close()

    # Convert Out8.hex
    ifname = "./Out8.hex"
    ifname_prefix = ifname.split(".hex")[0]
    ofname = ifname_prefix+".dat"
    rf = FileReader(ifname).open()
    wf = FileWriter(ofname).open()
    lines = rf.readlines()
    for l in lines:
        line = l.rstrip("\n")
        wb = bytearray.fromhex(BYTE_ZERO + BYTE_ZERO + BYTE_ZERO + line)
        wb.reverse()
        wf.write(wb)
    rf.close()
    wf.close()

    # Convert W2.hex
    ifname = "./W2.hex"
    ifname_prefix = ifname.split(".hex")[0]
    ofname = ifname_prefix+".dat"
    rf = FileReader(ifname).open()
    wf = FileWriter(ofname).open()
    lines = rf.readlines()
    for l in lines:
        line = l.rstrip("\n")
        wb = bytearray.fromhex("000"+line)
        wb.reverse()
        wf.write(wb)
    rf.close()
    wf.close()

    # Convert Bias32.hex
    ifname = "./Bias32.hex"
    ifname_prefix = ifname.split(".hex")[0]
    ofname = ifname_prefix+".dat"
    rf = FileReader(ifname).open()
    wf = FileWriter(ofname).open()
    lines = rf.readlines()
    for l in lines:
        line = l.rstrip("\n")
        wb = bytearray.fromhex(line)
        wb.reverse()
        wf.write(wb)
    rf.close()
    wf.close()
