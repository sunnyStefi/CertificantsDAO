//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;
//named-imports

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {ERC165Upgradeable} from "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @notice This contract govern the creation, transfer and management of certificates.
 */
contract CourseFactory is Initializable, AccessControlUpgradeable, UUPSUpgradeable {
    enum Difficulty {
        BEGINNER,
        INTERMEDIATE,
        ADVANCED,
        PROFESSIONAL
    }

    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableSet for EnumerableSet.UintSet;

    bytes32 public constant ADMIN = keccak256("ADMIN");
    bytes32 public constant EVALUATOR = keccak256("EVALUATOR");
    bytes32 public constant STUDENT = keccak256("STUDENT"); //todo assign
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    event CertificateCreated();
    event DefaultRolesAssigned();

    address private s_defaultAdmin;

    mapping(uint256 => CourseStruct) private s_idToCourse;
    mapping(address => uint256) private s_certificatesOwned;
    EnumerableSet.UintSet s_certificatesIds;
    EnumerableSet.AddressSet s_certificatesOwners;

    uint256[49] __gap;

    //connect with studentPath later
    struct TestStruct {
        Difficulty difficulty;
        string uri;
    }

    //connect with studentPath later
    struct CertificateStruct {
        string uri;
    }

    struct SectionStruct {
        string uri;
        bool isCompleted;
        mapping(uint256 => LessonsStruct) lessons;
    }

    struct LessonsStruct {
        string uri;
        bool isCompleted;
        string quizUri;
        bool isQuizPassed;
    }

    struct CourseStruct {
        //1. places
        uint256 places_total;
        uint256 places_available;
        //2. test
        TestStruct[] tests;
        //3. certification
        CertificateStruct certification;
        //4. sections
        //4.1 lessons
        //4.1.1 quiz
        mapping(uint256 => SectionStruct) sections;
        //others
        address creator;
        bool isOpen;
        string uri;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address defaultAdmin, address upgrader) public initializer {
        __AccessControl_init();
        __UUPSUpgradeable_init();

        _setRoleAdmin(ADMIN, ADMIN);
        _setRoleAdmin(EVALUATOR, ADMIN);

        _grantRole(ADMIN, _msgSender());
        _grantRole(ADMIN, address(this));
        _grantRole(ADMIN, defaultAdmin);

        _grantRole(UPGRADER_ROLE, upgrader);

        s_defaultAdmin = defaultAdmin;

        emit DefaultRolesAssigned();
    }

    function createCourse(address from, uint256 id, bytes memory data) public onlyRole(ADMIN) returns (uint256) {
        s_certificatesIds.add(id);
        s_certificatesOwners.add(from);
        s_certificatesOwned[from] += 1;
        emit CertificateCreated();
        return id;
    }

    /**
     * Getters
     */
    function getCertificateIds() public view returns (uint256[] memory) {
        return s_certificatesIds.values();
    }
    // PROXY

    function _authorizeUpgrade(address newImplementation) internal override onlyRole(UPGRADER_ROLE) {}
}
