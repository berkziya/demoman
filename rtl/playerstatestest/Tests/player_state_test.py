import cocotb
from cocotb.triggers import RisingEdge, Timer
from cocotb.clock import Clock
import random


#This function helps us see the values of the signals in our design.
def Log_Design(dut):
    #Log whatever signal you want from the datapath, called before positive clock edge
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

    # start the clock
    clock = Clock(dut.clock, 2, units="us")
    cocotb.start_soon(clock.start())


    dut.left.value = 0
    dut.right.value = 0
    dut.attack.value = 0

    await RisingEdge(dut.clock)
    await RisingEdge(dut.clock)



    await RisingEdge(dut.clock)
    await Timer(1, units="us")

    # 0 idle, 1 right, 2 left, 4 attack start, 7 attack active
    expected_next_state = 0
    

    localframecounter = 0
    # To check the attack states' frame counts
    

    for j in range(1000):
        randomnumber = random.randint(0,3)
        if randomnumber == 0:
            match dut.State.value:
                case 0:
                    expected_next_state = 2
                case 1:
                    expected_next_state = 2
                case 2:
                    expected_next_state = 2
                case 4:
                    expected_next_state = 7
                case 7:
                    expected_next_state = 0
            dut.Left.value = 1
            dut.Right.value = 0
            dut.Attack.value = 0
        elif randomnumber == 1:
            match dut.State.value:
                case 0:
                    expected_next_state = 1
                case 1:
                    expected_next_state = 1
                case 2:
                    expected_next_state = 1
                case 4:
                    expected_next_state = 7
                case 7:
                    expected_next_state = 0
            dut.Left.value = 0
            dut.Right.value = 1
            dut.Attack.value = 0
        elif randomnumber == 2:
            match dut.State.value:
                case 0:
                    expected_next_state = 4
                case 1:
                    expected_next_state = 4
                case 2:
                    expected_next_state = 4
                case 4:
                    expected_next_state = 7
                case 7:
                    expected_next_state = 0
            dut.Left.value = 0
            dut.Right.value = 0
            dut.Attack.value = 1
        else:
            match dut.State.value:
                case 0:
                    expected_next_state = 0
                case 1:
                    expected_next_state = 0
                case 2:
                    expected_next_state = 0
                case 4:
                    expected_next_state = 7
                case 7:
                    expected_next_state = 0
            dut.Left.value = 0
            dut.Right.value = 0
            dut.Attack.value = 0
        # Check if the output matches the expected value
        await RisingEdge(dut.clock)
        await Timer(1, units='us')
        if dut.State.value != expected_next_state:
            test_failed = True
            cocotb.log.error(
                f"MISMATCH for State={dut.State.value}. Expected={(expected_next_state)}, Got={dut.State.value}" #indicate for which value the error occured
            )
            Log_Design(dut)
        else:
            cocotb.log.info(
                f"PASSED for State={dut.State.value} = {(expected_next_state)}"
            )

 

    # Final evaluation of the test
    if test_failed:
        raise AssertionError("Test failed!")
    else:
        cocotb.log.info("Successful test!")