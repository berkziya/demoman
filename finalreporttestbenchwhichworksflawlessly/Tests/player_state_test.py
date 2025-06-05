import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
import random


#This function helps us see the values of the signals in our design.
def Log_Design(dut):
    #Log whatever signal you want from the datapath, called before positive clk edge
    s1 = "dut"
    obj1 = dut
    wires = []
    submodules = []
    for attribute_name in dir(obj1):
        attribute = getattr(obj1, attribute_name)
        if attribute.__class__.__module__.startswith('cocotb.handle'):
            if(attribute.__class__.__name__ == 'ModifiableObject'):
                wires.append((attribute_name, attribute.value) )
            elif(attribute.__class__.__name__ == 'HierarchyObject'):
                submodules.append((attribute_name, attribute.get_definition_name()) )
            elif(attribute.__class__.__name__ == 'HierarchyArrayObject'):
                submodules.append((attribute_name, f"[{len(attribute)}]") )
            elif(attribute.__class__.__name__ == 'NonHierarchyIndexableObject'):
                wires.append((attribute_name, [v for v in attribute.value] ) )
            #else:
                #print(f"{attribute_name}: {type(attribute)}")
                
        #else:
            #print(f"{attribute_name}: {type(attribute)}")
    #for sub in submodules:
    #    print(f"{s1}.{sub[0]:<16}is {sub[1]}")
    for wire in wires:
        print(f"{s1}.{wire[0]:<16}= {wire[1]}")

@cocotb.test()

async def player_state_test(dut):
    """Testbench for player module."""
    
    test_failed = False  #Test failure state

    # start the clk
    clk = Clock(dut.clk, 2, units="us")
    cocotb.start_soon(clk.start())


    dut.rst.value = 0
    dut.left.value = 0
    dut.right.value = 0
    dut.attack.value = 0
    dut.hitFlag.value = 0 #0 = no hit, 1 = hit by basic attack, 2 = hit by directional attack
    dut.block.value = 3

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    await Timer(1, units="us")

    # 0 idle, 1 right, 2 left, 3 basic attack start, 4 basic attack active, 5 basic attack pull
    # 6 direcional attack start, 7 direcional attack active, 8 direcional attack pull
    # 9 hitstun, 10 blockstun
    expected_next_state = 0
    

    jlastswitch = 0
    # To check the attack states' frame counts
    
    blocksleft = 3

    currentstunlength = 0 
    #15 when bacic attack lands, 13 when basic attack is blocked
    #14 when directional attack lands, 12 when directional attack is blocked

    hitFlagValtoSet = 0

    jmaximum = 3000

    errorcases = 0
    
    for j in range(jmaximum):

        if blocksleft < 0:
            blocksleft = 0
        dut.block.value = blocksleft

        randomhitevent = random.randint(0,1) #0 = basic attack, 1 = directional attack
        #hit by an attack every 40 cycles, randomly chosen as basic or directional
        if (j > 0) and ((j % 40) == 0):
            if randomhitevent == 0:
                hitFlagValtoSet = 1
            else:
                hitFlagValtoSet = 2
        else:
            hitFlagValtoSet = 0

        randomnumber = random.randint(0,6) 
        #0,1 = left; 2,3 = right; 4 = attack; 5,6 = no button pressed
        
        if hitFlagValtoSet == 0:
            if randomnumber == 0 or randomnumber == 1: #left
                match dut.current_state.value:
                    case 0:
                        expected_next_state = 2
                    case 1:
                        expected_next_state = 2
                    case 2:
                        expected_next_state = 2
                    case 3:
                        if (j-jlastswitch) < 5:
                            expected_next_state = 3
                        else:
                            expected_next_state = 4
                            jlastswitch = j
                    case 4:
                        if (j-jlastswitch) < 2:
                            expected_next_state = 4
                        else:
                            expected_next_state = 5
                            jlastswitch = j
                    case 5:
                        if (j-jlastswitch) < 16:
                            expected_next_state = 5
                        else:
                            expected_next_state = 2
                            jlastswitch = j
                    case 6:
                        if (j-jlastswitch) < 4:
                            expected_next_state = 6
                        else:
                            expected_next_state = 7
                            jlastswitch = j
                    case 7:
                        if (j-jlastswitch) < 3:
                            expected_next_state = 7
                        else:
                            expected_next_state = 8
                            jlastswitch = j
                    case 8:
                        if (j-jlastswitch) < 15:
                            expected_next_state = 8
                        else:
                            expected_next_state = 2
                            jlastswitch = j
                    case 9:
                        if (j-jlastswitch) < currentstunlength:
                            expected_next_state = 9
                        else:
                            expected_next_state = 2
                            jlastswitch = j
                    case 10:
                        if (j-jlastswitch) < currentstunlength:
                            expected_next_state = 10
                        else:
                            expected_next_state = 2
                            jlastswitch = j
                dut.left.value = 1
                dut.right.value = 0
                dut.attack.value = 0
            elif randomnumber == 2 or randomnumber == 3: #right
                match dut.current_state.value:
                    case 0:
                        expected_next_state = 1
                    case 1:
                        expected_next_state = 1
                    case 2:
                        expected_next_state = 1
                    case 3:
                        if (j-jlastswitch) < 5:
                            expected_next_state = 3
                        else:
                            expected_next_state = 4
                            jlastswitch = j
                    case 4:
                        if (j-jlastswitch) < 2:
                            expected_next_state = 4
                        else:
                            expected_next_state = 5
                            jlastswitch = j
                    case 5:
                        if (j-jlastswitch) < 16:
                            expected_next_state = 5
                        else:
                            expected_next_state = 1
                            jlastswitch = j
                    case 6:
                        if (j-jlastswitch) < 4:
                            expected_next_state = 6
                        else:
                            expected_next_state = 7
                            jlastswitch = j
                    case 7:
                        if (j-jlastswitch) < 3:
                            expected_next_state = 7
                        else:
                            expected_next_state = 8
                            jlastswitch = j
                    case 8:
                        if (j-jlastswitch) < 15:
                            expected_next_state = 8
                        else:
                            expected_next_state = 1
                            jlastswitch = j
                    case 9:
                        if (j-jlastswitch) < currentstunlength:
                            expected_next_state = 9
                        else:
                            expected_next_state = 1
                            jlastswitch = j
                    case 10:
                        if (j-jlastswitch) < currentstunlength:
                            expected_next_state = 10
                        else:
                            expected_next_state = 1
                            jlastswitch = j
                dut.left.value = 0
                dut.right.value = 1
                dut.attack.value = 0
            elif randomnumber == 4: #attack
                match dut.current_state.value:
                    case 0:
                        expected_next_state = 3
                        jlastswitch = j
                    case 1:
                        expected_next_state = 6
                        jlastswitch = j
                    case 2:
                        expected_next_state = 6
                        jlastswitch = j
                    case 3:
                        if (j-jlastswitch) < 5:
                            expected_next_state = 3
                        else:
                            expected_next_state = 4
                            jlastswitch = j
                    case 4:
                        if (j-jlastswitch) < 2:
                            expected_next_state = 4
                        else:
                            expected_next_state = 5
                            jlastswitch = j
                    case 5:
                        if (j-jlastswitch) < 16:
                            expected_next_state = 5
                        else:
                            expected_next_state = 3
                            jlastswitch = j
                    case 6:
                        if (j-jlastswitch) < 4:
                            expected_next_state = 6
                        else:
                            expected_next_state = 7
                            jlastswitch = j
                    case 7:
                        if (j-jlastswitch) < 3:
                            expected_next_state = 7
                        else:
                            expected_next_state = 8
                            jlastswitch = j
                    case 8:
                        if (j-jlastswitch) < 15:
                            expected_next_state = 8
                        else:
                            expected_next_state = 3
                            jlastswitch = j
                    case 9:
                        if (j-jlastswitch) < currentstunlength:
                            expected_next_state = 9
                        else:
                            expected_next_state = 3
                            jlastswitch = j
                    case 10:
                        if (j-jlastswitch) < currentstunlength:
                            expected_next_state = 10
                        else:
                            expected_next_state = 3
                            jlastswitch = j
                dut.left.value = 0
                dut.right.value = 0
                dut.attack.value = 1
            else:
                match dut.current_state.value:
                    case 0:
                        expected_next_state = 0
                    case 1:
                        expected_next_state = 0
                    case 2:
                        expected_next_state = 0
                    case 3:
                        if (j-jlastswitch) < 5:
                            expected_next_state = 3
                        else:
                            expected_next_state = 4
                            jlastswitch = j
                    case 4:
                        if (j-jlastswitch) < 2:
                            expected_next_state = 4
                        else:
                            expected_next_state = 5
                            jlastswitch = j
                    case 5:
                        if (j-jlastswitch) < 16:
                            expected_next_state = 5
                        else:
                            expected_next_state = 0
                            jlastswitch = j
                    case 6:
                        if (j-jlastswitch) < 4:
                            expected_next_state = 6
                        else:
                            expected_next_state = 7
                            jlastswitch = j
                    case 7:
                        if (j-jlastswitch) < 3:
                            expected_next_state = 7
                        else:
                            expected_next_state = 8
                            jlastswitch = j
                    case 8:
                        if (j-jlastswitch) < 15:
                            expected_next_state = 8
                        else:
                            expected_next_state = 0
                            jlastswitch = j
                    case 9:
                        if (j-jlastswitch) < currentstunlength:
                            expected_next_state = 9
                        else:
                            expected_next_state = 0
                            jlastswitch = j
                    case 10:
                        if (j-jlastswitch) < currentstunlength:
                            expected_next_state = 10
                        else:
                            expected_next_state = 0
                            jlastswitch = j
                dut.left.value = 0
                dut.right.value = 0
                dut.attack.value = 0

        elif hitFlagValtoSet == 1: #hit by basic attack
            currentstunlength = 15
            match dut.current_state.value:
                case 0:
                    expected_next_state = 9
                    jlastswitch = j
                case 1:
                    expected_next_state = 9
                    jlastswitch = j
                case 2:
                    if blocksleft > 0:
                        currentstunlength = 13
                        expected_next_state = 10
                        blocksleft -= 1
                        jlastswitch = j
                    else:
                        currentstunlength = 15
                        expected_next_state = 9
                        jlastswitch = j
                case 3:
                    expected_next_state = 9
                    jlastswitch = j
                case 4:
                    expected_next_state = 9
                    jlastswitch = j
                case 5:
                    expected_next_state = 9
                    jlastswitch = j
                case 6:
                    expected_next_state = 9
                    jlastswitch = j
                case 7:
                    expected_next_state = 9
                    jlastswitch = j
                case 8:
                    expected_next_state = 9
                    jlastswitch = j
                case 9:
                    expected_next_state = 9
                    jlastswitch = j
                case 10:
                    expected_next_state = 10
                    jlastswitch = j

        else: #hit by directional attack
            currentstunlength = 14
            match dut.current_state.value:
                case 0:
                    expected_next_state = 9
                    jlastswitch = j
                case 1:
                    expected_next_state = 9
                    jlastswitch = j
                case 2:
                    if blocksleft > 0:
                        currentstunlength = 12
                        expected_next_state = 10
                        blocksleft -= 1
                        jlastswitch = j
                    else:
                        currentstunlength = 14
                        expected_next_state = 9
                        jlastswitch = j
                case 3:
                    expected_next_state = 9
                    jlastswitch = j
                case 4:
                    expected_next_state = 9
                    jlastswitch = j
                case 5:
                    expected_next_state = 9
                    jlastswitch = j
                case 6:
                    expected_next_state = 9
                    jlastswitch = j
                case 7:
                    expected_next_state = 9
                    jlastswitch = j
                case 8:
                    expected_next_state = 9
                    jlastswitch = j
                case 9:
                    expected_next_state = 9
                    jlastswitch = j
                case 10:
                    expected_next_state = 10
                    jlastswitch = j


        dut.hitFlag.value = hitFlagValtoSet
            
            
        # Check if the output matches the expected value
        await RisingEdge(dut.clk)
        await Timer(1, units='us')
        if dut.current_state.value != expected_next_state:
            test_failed = True
            errorcases += 1
            cocotb.log.error(
                f"MISMATCH for current_state={dut.current_state.value}. Expected={(expected_next_state)}, Got={dut.current_state.value}" #indicate for which value the error occured
            )
            Log_Design(dut)
        else:
            cocotb.log.info(
                f"PASSED for current_state={dut.current_state.value} = {(expected_next_state)}" #indicate for which value the test passed
            )
            

 

    # Final evaluation of the test
    if test_failed:
        raise AssertionError('Test failed!', errorcases,'/',jmaximum,' cycles were problematic.')
    else:
        cocotb.log.info("Successful test!")