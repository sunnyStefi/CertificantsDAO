// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import {Test, console} from "forge-std/Test.sol";
import {CourseFactory} from "../src/CertificateFactory/CourseFactory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";

contract CourseFactoryTest is Test {
    address ALICE_ADDRESS_ANVIL = makeAddr("ALICE_ADDRESS_ANVIL");
    string TEST_URI = "ipfs://123";
    string[] TEST_URI_ARRAY = [TEST_URI];
    CourseFactory courseFactory;
    uint256 placesTotal = 10;
    ERC1967Proxy proxy;
    VRFCoordinatorV2Mock vrfCoordinatorV2Mock;
    uint96 baseFee = 0.25 ether;
    uint32 callbackgaslimit = 10000;
    uint96 gasPriceLink = 1e9; //1gwei LINK

    function setUp() public {
        vm.startPrank(ALICE_ADDRESS_ANVIL);
        vm.deal(ALICE_ADDRESS_ANVIL, 5 ether);
        vrfCoordinatorV2Mock = new VRFCoordinatorV2Mock(baseFee, gasPriceLink);
        courseFactory = new CourseFactory(address(vrfCoordinatorV2Mock));
        uint64 subscriptionId = vrfCoordinatorV2Mock.createSubscription();
        vrfCoordinatorV2Mock.fundSubscription(subscriptionId, 3 ether);

        bytes memory initializerData = abi.encodeWithSelector(
            CourseFactory.initialize.selector,
            ALICE_ADDRESS_ANVIL,
            ALICE_ADDRESS_ANVIL,
            address(vrfCoordinatorV2Mock),
            bytes32("0x"),
            subscriptionId,
            uint32(callbackgaslimit)
        );
        proxy = new ERC1967Proxy(address(courseFactory), initializerData);
        vrfCoordinatorV2Mock.addConsumer(subscriptionId, address(proxy));

        vm.stopPrank();
    }

    // function test_createOneCourse() public {
    //     vm.startPrank(ALICE_ADDRESS_ANVIL);
    //     CourseFactory(payable(proxy)).createCourse(
    //         TEST_URI, placesTotal, TEST_URI_ARRAY, TEST_URI, TEST_URI_ARRAY, TEST_URI_ARRAY
    //     );
    //     vm.stopPrank();
    //     vm.assertEq(CourseFactory(payable(proxy)).getCreator(1), ALICE_ADDRESS_ANVIL);
    // }

    // function test_createMoreCourses() public {
    //     vm.startPrank(ALICE_ADDRESS_ANVIL);
    //     CourseFactory(payable(proxy)).createCourse(
    //         TEST_URI, placesTotal, TEST_URI_ARRAY, TEST_URI, TEST_URI_ARRAY, TEST_URI_ARRAY
    //     );
    //     CourseFactory(payable(proxy)).createCourse(
    //         TEST_URI, placesTotal, TEST_URI_ARRAY, TEST_URI, TEST_URI_ARRAY, TEST_URI_ARRAY
    //     );
    //     vm.stopPrank();
    //     vm.assertEq(CourseFactory(payable(proxy)).getIdCounter(), 2);
    // }

    /**
     * Enter the course
     * time up
     * Perform upkeep
     * We pretend to be chainlink VRF
     */
    function test_sendRandomWordsRequest() public {
        vm.startPrank(ALICE_ADDRESS_ANVIL);
        vm.recordLogs();
        CourseFactory.CourseStruct memory createdCourse;
        uint256 requestIdResult;
        (createdCourse, requestIdResult) = CourseFactory(payable(proxy)).createCourse(
            TEST_URI, placesTotal, TEST_URI_ARRAY, TEST_URI, TEST_URI_ARRAY, TEST_URI_ARRAY
        ); //emit requestId
        Vm.Log[] memory entries = vm.getRecordedLogs();
        bytes32 requestId = entries[1].topics[1];

        //pretend to be chainlink vrf
        VRFCoordinatorV2Mock(address(vrfCoordinatorV2Mock)).fulfillRandomWords(
            uint256(requestIdResult), address(courseFactory)
        );
        // console.log(uint256(requestId));
        // console.log(uint256(requestIdResult));

        vm.stopPrank();
    }
}
