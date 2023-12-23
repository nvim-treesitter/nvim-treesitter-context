interface SomeInterface {
    function someFunction(uint a, uint b) external returns (uint c);
    function testFunction(uint) external returns (uint);
}

contract Contract {
    event SomeEvent(
        uint a,
        uint b,
        uint c,
        uint d
    );

    error SomeError(
        uint a,
        uint b,
        uint c,
        uint d
    );

    struct SomeStruct {
        uint a;
        uint b;
        uint c;
        uint d;
    }

    enum SomeEnum {
        Entry1,
        Entry2,
        Entry3,
        Entry4
    }

    constructor() {
        // do some construction
    }

    fallback() external payable {
        // this is
        // fallback
    }

    receive() external payable {
        // this is
        // receive
        // function
    }

    function someFunction(uint a, uint b) external pure returns (uint _c) {
        _c = a + b;

        if (true) {
            // do
            // something
            // in if statement
            emit SomeEvent(1, 2,
                          3, 4);
        } else {
            // do
            // something
            // in else statement

            revert SomeError(
                1,
                2,
                3, 4
            );
        }

        for (uint i = 0; i < 10; i++) {
            // something
            // in loop

            uint j = 0;
            while (j < 5) {
                j++;
                // something
                // something

                try {
                    // will error
                    // need to catch
                } catch (bytes memory reason) {
                    // catch
                    // do some cleanup
                }
            }

            do {
                // this is do
                // while

                unchecked {
                    j++;
                }
            } while (j < 5);
        }
    }

    modifier withSomething(uint a) {
        // modifier logic
        _;
    }
}

library SomeLibrary {
    function libraryFunction(uint a, uint b, uint c, uint d) internal pure {
        a = 1;
        b = 2;
        c = 3;
        d = 4;
    }
}
