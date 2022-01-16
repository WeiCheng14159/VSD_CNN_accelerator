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
            self.file = open(self.filename, 'w')
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
    ofname = [ifname_prefix+"_0.hex", ifname_prefix+"_1.hex",
              ifname_prefix+"_2.hex", ifname_prefix+"_3.hex"]
    rf = FileReader(ifname).open()
    wf = [FileWriter(ofname[0]).open(), FileWriter(ofname[1]).open(
    ), FileWriter(ofname[2]).open(), FileWriter(ofname[3]).open()]
    nl_cnt = 1
    lines = rf.readlines()
    for l in lines:
        line = l.rstrip("\n")
        wf[0].write(line + " ")
        wf[1].write(BYTE_ZERO + " ")
        wf[2].write(BYTE_ZERO + " ")
        wf[3].write(BYTE_ZERO + " ")
        if nl_cnt % 16 == 0:
            for f in wf:
                f.write("\n")
        nl_cnt += 1
    rf.close()
    for _ in wf:
        _.close()

    # Convert param.hex
    ifname = "./param.hex"
    ifname_prefix = ifname.split(".hex")[0]
    ofname = [ifname_prefix+"_0.hex", ifname_prefix+"_1.hex",
              ifname_prefix+"_2.hex", ifname_prefix+"_3.hex"]
    rf = FileReader(ifname).open()
    wf = [FileWriter(ofname[0]).open(), FileWriter(ofname[1]).open(
    ), FileWriter(ofname[2]).open(), FileWriter(ofname[3]).open()]
    nl_cnt = 1
    lines = rf.readlines()
    for l in lines:
        line = l.rstrip("\n")
        wf[0].write(line[6:8] + " ")
        wf[1].write(line[4:6] + " ")
        wf[2].write(line[2:4] + " ")
        wf[3].write(line[0:2] + " ")
        if nl_cnt % 16 == 0:
            for f in wf:
                f.write("\n")
        nl_cnt += 1
    rf.close()
    for _ in wf:
        _.close()

    # Convert W2.hex
    ifname = "./W2.hex"
    ifname_prefix = ifname.split(".hex")[0]
    ofname = [ifname_prefix+"_0.hex", ifname_prefix+"_1.hex",
              ifname_prefix+"_2.hex", ifname_prefix+"_3.hex"]
    rf = FileReader(ifname).open()
    wf = [FileWriter(ofname[0]).open(), FileWriter(ofname[1]).open(
    ), FileWriter(ofname[2]).open(), FileWriter(ofname[3]).open()]
    nl_cnt = 1
    lines = rf.readlines()
    for l in lines:
        line = l.rstrip("\n")
        wf[0].write(line[3:5] + " ")
        wf[1].write(line[1:3] + " ")
        wf[2].write("0" + line[0:1] + " ")
        wf[3].write(BYTE_ZERO + " ")
        if nl_cnt % 16 == 0:
            for f in wf:
                f.write("\n")
        nl_cnt += 1
    rf.close()
    for _ in wf:
        _.close()

    # Convert Bias32.hex
    ifname = "./Bias32.hex"
    ifname_prefix = ifname.split(".hex")[0]
    ofname = [ifname_prefix+"_0.hex", ifname_prefix+"_1.hex",
              ifname_prefix+"_2.hex", ifname_prefix+"_3.hex"]
    rf = FileReader(ifname).open()
    wf = [FileWriter(ofname[0]).open(), FileWriter(ofname[1]).open(
    ), FileWriter(ofname[2]).open(), FileWriter(ofname[3]).open()]
    nl_cnt = 1
    lines = rf.readlines()
    for l in lines:
        line = l.rstrip("\n")
        wf[0].write(line[6:8] + " ")
        wf[1].write(line[4:6] + " ")
        wf[2].write(line[2:4] + " ")
        wf[3].write(line[0:2] + " ")
        if nl_cnt % 16 == 0:
            for f in wf:
                f.write("\n")
        nl_cnt += 1
    rf.close()
    for _ in wf:
        _.close()
