//SPDX-License-Identifier:MIT

pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Test, console} from "forge-std/Test.sol";
import {CourseFactory} from "../src/CertificateFactory/CourseFactory.sol";
import {StudentPath} from "../src/CertificateFactory/StudentPath.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/vrf/mocks/VRFCoordinatorV2Mock.sol";
import {Vm} from "forge-std/Vm.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

contract CreateCourse is Script {
    address ALICE_ADDRESS_ANVIL = makeAddr("ALICE_ADDRESS_ANVIL");
    string TEST_URI = "ipfs://123";
    string[] TEST_URI_ARRAY = [TEST_URI];
    string[] TEST_LESSON_URI_ARRAY = [TEST_URI, TEST_URI, TEST_URI]; //3 lessons
    CourseFactory courseFactory;
    uint256 placesTotal = 10;
    ERC1967Proxy proxy;
    VRFCoordinatorV2Mock vrfCoordinatorV2Mock;
    uint96 baseFee = 0.25 ether;
    uint32 callbackgaslimit = type(uint32).max;
    uint96 gasPriceLink = 1e9; //1gwei LINK
    CourseFactory.CourseStruct createdCourse;

    function run() external returns (address, uint256) {
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
        uint256 requestIdResult;
        (createdCourse, requestIdResult) = CourseFactory(payable(proxy)).createCourse(
            TEST_URI, placesTotal, TEST_URI, TEST_LESSON_URI_ARRAY, TEST_LESSON_URI_ARRAY
        );
        vm.recordLogs();
        vrfCoordinatorV2Mock.fulfillRandomWords(uint256(requestIdResult), address(proxy));
        Vm.Log[] memory entries = vm.getRecordedLogs();
        return (address(proxy), uint256(entries[0].topics[1]));
    }
}

contract CreateStudentPath is Script {
    uint256 randomCourseId;
    address courseProxy;
    address ALICE_ADDRESS_ANVIL = makeAddr("ALICE_ADDRESS_ANVIL");
    address STUDENT_ADDRESS = makeAddr("STUDENT_ADDRESS");
    CreateCourse createCourse;
    StudentPath studentPath;
    ERC1967Proxy studentProxy;

    function run() external returns (address, uint256) {
        createCourse = new CreateCourse();
        studentPath = new StudentPath();
        (courseProxy, randomCourseId) = createCourse.run();
        bytes memory initializerData = abi.encodeWithSelector(
            StudentPath.initialize.selector, ALICE_ADDRESS_ANVIL, ALICE_ADDRESS_ANVIL, address(courseProxy)
        );
        studentProxy = new ERC1967Proxy(address(studentPath), initializerData);

        StudentPath(payable(studentProxy)).addCourseAndLessonsToPath(randomCourseId, STUDENT_ADDRESS);
        return (address(studentProxy), randomCourseId);
    }
}

