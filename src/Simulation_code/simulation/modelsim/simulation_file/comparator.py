with open("res_kexp.txt", "r") as file1:
    with open("result.txt", "r") as file2:
        for line in file1:
            int1 = int(line)
            str2 = file2.readline()
            int2 = int(str2)
            if (not int1 == int2):
                print(int1)
                print(int2)
                print("\n\n\n")
