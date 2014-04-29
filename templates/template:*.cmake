cmake_minimum_required (VERSION 2.8)

# projectname is the same as the main-executable
project(%HERE%%FDIR%)

add_definitions('-g')
add_definitions('-Wall')
#add_definitions('-std=c++11')

add_executable(${PROJECT_NAME} ${PROJECT_NAME}.cpp)

add_custom_target(${PROJECT_NAME}-symlink ALL ln --force -s ${CMAKE_CURRENT_BINARY_DIR}/${PROJECT_NAME} ${CMAKE_SOURCE_DIR}/${PROJECT_NAME} DEPENDS ${PROJECT_NAME})
set_directory_properties(PROPERTIES ADDITIONAL_MAKE_CLEAN_FILES ${CMAKE_SOURCE_DIR}/${PROJECT_NAME})
