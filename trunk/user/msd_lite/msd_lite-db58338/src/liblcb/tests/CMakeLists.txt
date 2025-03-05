
############################# INITIAL SECTION ##########################
cmake_minimum_required(VERSION 3.20)

############################# OPTIONS SECTION ##########################


############################# INCLUDE SECTION ##########################
find_path(CUNIT_INCLUDE_DIR NAMES CUnit/CUnit.h)
find_library(CUNIT_LIBRARY NAMES cunit libcunit cunitlib)

############################# MACRO SECTION ############################


############################# CONFIG SECTION ###########################

message(STATUS "liblcb tests enabled!")

################################ SUBDIRS SECTION #######################


############################ TARGETS SECTION ###########################
# Testing binary.
add_executable(test_base64 base64/main.c)
add_executable(test_ecdsa ecdsa/main.c)
add_executable(test_hash hash/main.c)
add_executable(test_threadpool threadpool/main.c
		../src/threadpool/threadpool.c
		../src/threadpool/threadpool_msg_sys.c)
target_include_directories(test_threadpool PRIVATE ${CUNIT_INCLUDE_DIR})
target_link_libraries(test_threadpool ${CUNIT_LIBRARY} ${CMAKE_REQUIRED_LIBRARIES})


# Define tests.
add_test(NAME test_base64 COMMAND $<TARGET_FILE:test_base64>)
add_test(NAME test_ecdsa COMMAND $<TARGET_FILE:test_ecdsa>)
add_test(NAME test_hash COMMAND $<TARGET_FILE:test_hash>)
add_test(NAME test_threadpool COMMAND $<TARGET_FILE:test_threadpool>)


##################### INSTALLATION #####################################

