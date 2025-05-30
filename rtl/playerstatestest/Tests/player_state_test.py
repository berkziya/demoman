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

    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)



    await RisingEdge(dut.clk)
    await Timer(1, units="us")

    # 0 idle, 1 right, 2 left, 4 attack start, 7 attack active
    expected_next_state = 0
    

    jlastswitch = 0
    # To check the attack states' frame counts
    

    for j in range(1000):
        randomnumber = random.randint(0,3)
        if randomnumber == 0:
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
            dut.left.value = 1
            dut.right.value = 0
            dut.attack.value = 0
        elif randomnumber == 1:
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
            dut.left.value = 0
            dut.right.value = 1
            dut.attack.value = 0
        elif randomnumber == 2:
            match dut.current_state.value:
                case 0:
                    expected_next_state = 3
                    jlastswitch = j
                case 1:
                    expected_next_state = 3
                    jlastswitch = j
                case 2:
                    expected_next_state = 3
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
            dut.left.value = 0
            dut.right.value = 0
            dut.attack.value = 0
        # Check if the output matches the expected value
        await RisingEdge(dut.clk)
        await Timer(1, units='us')
        if dut.current_state.value != expected_next_state:
            test_failed = True
            cocotb.log.error(
                f"MISMATCH for current_state={dut.current_state.value}. Expected={(expected_next_state)}, Got={dut.current_state.value}, counter = {dut.counter.value}" #indicate for which value the error occured
            )
            Log_Design(dut)
        else:
            cocotb.log.info(
                f"PASSED for current_state={dut.current_state.value} = {(expected_next_state)}, counter = {dut.counter.value}" #indicate for which value the test passed
            )

 

    # Final evaluation of the test
    if test_failed:
        raise AssertionError("Test failed!")
    else:
        cocotb.log.info("Successful test!")