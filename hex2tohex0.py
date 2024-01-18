import pprint
import struct
import sys

def main():
    hex2path = sys.argv[1]
    hex0path = sys.argv[2]
    base_address = int(sys.argv[3], 16)
    labels = find_labels(hex2path, base_address)
    print_replace(hex2path, hex0path, labels, base_address)
    for label in ['addr_packet', 'GDT_start', 'IDT_locator_32', 'IDT_locator_16']:
        if label in labels and labels[label] % 16 != 0:
            print("ERROR: label %s not aligned to 16 byte boundary (%x)!" % (label, labels[label]))
            sys.exit(1)
    if 'past_MBR' in labels and labels['past_MBR'] != 0x7e00 and labels['past_MBR'] != 0x8000:
            print("ERROR: label past_MBR is not 0x7e00 or 0x8000")
            sys.exit(1)


def find_labels(hex2path, base_address):
    cur_address = base_address
    labels = {}
    with open(hex2path, "r") as h2f:
        for line in h2f:
            if line[0] == ':':
                if line[1:].strip() in labels:
                    print("ERROR: duplicate label: %s" % line[1:])
                    sys.exit(1)
                labels[line[1:].strip()] = cur_address
            else:
                cur_address += count_hex(line)
    return labels

def count_hex(line):
    count = 0
    pos = 0
    while pos < len(line):
        if line[pos] in ['#', ';']:
            break

        if line[pos].isalnum():
            pos += 2
            count += 1
            continue

        if line[pos] == '&' or line[pos] == '%':
            count += 4
            pos += 1
            while line[pos].isalnum() or line[pos] == '_':
                pos += 1
            continue

        if line[pos] == '$' or line[pos] == '@':
            count += 2
            pos += 1
            while line[pos].isalnum() or line[pos] == '_':
                pos += 1
            continue

        if line[pos] == '!':
            count += 1
            pos += 1
            while line[pos].isalnum() or line[pos] == '_':
                pos += 1
            continue

        pos += 1

    return count

def print_replace(hex2path, hex0path, labels, base_address):
    cur_address = base_address
    print_header_comment = False
    with open(hex2path, "r")  as h2f, open(hex0path, "w") as h0f:
        for line in h2f:

            for label, address in labels.items():
                if len(label) + 1 > len(littleendian(address)):
                    # the label (with &) is long and we need to pad the replaced address with extra spaces
                    extra_spaces = ' ' * (len(label) + 1 - len(littleendian(address)))
                    line = line.replace("&" + label + " ", littleendian(address) + extra_spaces + " ")
                else:
                    # the label (with &) is short and we need to remove extra spaces to match the length of the address
                    extra_spaces = ' ' * (len(littleendian(address)) - (len(label) + 1))
                    line = line.replace("&" + label + extra_spaces + " ", littleendian(address) + " ")
                    # if there were no extra spaces make sure the replacement can work anyway
                    line = line.replace("&" + label + " ", littleendian(address) + " ")

                if len(label) + 1 > len(littleendian16(address)):
                    # the label (with $) is long and we need to pad the replaced address with extra spaces
                    extra_spaces = ' ' * (len(label) + 1 - len(littleendian16(address)))
                    line = line.replace("$" + label + " 00 00", littleendian16(address) + " 00 00" + extra_spaces)
                    line = line.replace("$" + label + " 08 00", littleendian16(address) + " 08 00" + extra_spaces)
                    line = line.replace("$" + label + " ", littleendian16(address) + extra_spaces + " ")
                else:
                    # the label (with $) is short and we need to remove extra spaces to match the length of the address
                    extra_spaces = ' ' * (len(littleendian16(address)) - (len(label) + 1))
                    line = line.replace("$" + label + extra_spaces + " ", littleendian16(address) + " ")
                    # if there were no extra spaces make sure the replacement can work anyway
                    line = line.replace("$" + label + " ", littleendian16(address) + " ")


                # XXX these functions could probably be unified!
                line = relative8bit_replace(line, cur_address, label, address)
                line = relative16bit_replace(line, cur_address, label, address)
                line = relative32bit_replace(line, cur_address, label, address)
                if line[0] == ":" and print_header_comment:
                        line = line.replace(":" + label + "\n", "#[" + format(address, "04X") + "]\n#:" + label + "\n")
            if line[0] == ":":
                line = "#" + line
            cur_address += count_hex(line)
            h0f.write(line)

            if line.startswith("#-"):
                print_header_comment = True
            else:
                print_header_comment = False

def littleendian(address):
    big_endian = format(address, "08X")
    return big_endian[6:8] + ' ' + big_endian[4:6] +  ' ' + big_endian[2:4] + ' ' + big_endian[0:2]


def littleendian16(address):
    big_endian = format(address, "04X")
    return big_endian[2:4] + ' ' + big_endian[0:2]


def relative8bit_replace(line, cur_address, label, address):
    pos = 0
    while pos < len(line):
        if line[pos] in ['#', ';']:
            break

        if line[pos].isalnum():
            pos += 2
            cur_address += 1
            continue

        if line[pos] == '&':
            return line

        if line[pos] == '%':
            return line

        if line[pos] == '$':
            return line

        if line[pos] == '@':
            return line

        if line[pos] == '!':
            cur_address += 1
            pos += 1
            end_pos = pos
            while line[end_pos].isalnum() or line[end_pos] == '_':
                end_pos += 1
            if label == line[pos:end_pos]:
                extra_spaces = ' ' * (end_pos - pos - 1)
                if address - cur_address > 0:
                    line = line.replace("!" + label, format(address - cur_address, "02X") + extra_spaces)
                else:
                    line = line.replace("!" + label, format(0x100 + address - cur_address, "02X") + extra_spaces)
            return line

        pos += 1
    return line

def relative16bit_replace(line, cur_address, label, address):
    pos = 0
    while pos < len(line):
        if line[pos] in ['#', ';']:
            break

        if line[pos].isalnum():
            pos += 2
            cur_address += 1
            continue

        if line[pos] == '&':
            return line

        if line[pos] == '%':
            return line

        if line[pos] == '$':
            return line

        if line[pos] == '!':
            return line

        if line[pos] == '@':
            cur_address += 2
            pos += 1
            end_pos = pos
            while line[end_pos].isalnum() or line[end_pos] == '_':
                end_pos += 1
            if label == line[pos:end_pos]:
                extra_spaces = ' ' * (end_pos - pos - 4)
                if address - cur_address > 0:
                    line = line.replace("@" + label, littleendian16(address - cur_address) + extra_spaces)
                else:
                    line = line.replace("@" + label, littleendian16(0x10000 + address - cur_address) + extra_spaces)
            return line

        pos += 1
    return line

def relative32bit_replace(line, cur_address, label, address):
    pos = 0
    while pos < len(line):
        if line[pos] in ['#', ';']:
            break

        if line[pos].isalnum():
            pos += 2
            cur_address += 1
            continue

        if line[pos] == '&':
            return line

        if line[pos] == '!':
            return line

        if line[pos] == '$':
            return line

        if line[pos] == '@':
            return line

        if line[pos] == '%':
            cur_address += 4
            pos += 1
            end_pos = pos
            while line[end_pos].isalnum() or line[end_pos] == '_':
                end_pos += 1
            if label == line[pos:end_pos]:
                label_len = end_pos - pos + 1
                if address - cur_address > 0:
                    if label_len > 11:
                        extra_spaces = ' ' * (label_len - 11)
                        line = line.replace("%" + label, littleendian(address - cur_address) + extra_spaces)
                    else:
                        extra_spaces = ' ' * (11 - label_len)
                        line = line.replace("%" + label + extra_spaces, littleendian(address - cur_address))
                else:
                    if label_len > 11:
                        extra_spaces = ' ' * (label_len - 11)
                        line = line.replace("%" + label, littleendian(0x100000000 + address - cur_address) + extra_spaces)
                    else:
                        extra_spaces = ' ' * (11 - label_len)
                        line = line.replace("%" + label + extra_spaces, littleendian(0x100000000 + address - cur_address))
            return line

        pos += 1
    return line


if __name__ == '__main__':
    main()      
