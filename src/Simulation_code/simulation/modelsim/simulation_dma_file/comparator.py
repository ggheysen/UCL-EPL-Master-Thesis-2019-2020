with open("res_fmo.txt", "r") as file1:
    with open("result_fmo.txt", "r") as file2:
        for line in file1:
            int1 = int(line)
            str2 = file2.readline()
            str3 = str2.split(":")
            int2 = int(str3[0])
            int3 = int(str3[1])
            if ((not int1 == int3)):
                print(int1)
                print(int2)
                print("\n\n\n")
