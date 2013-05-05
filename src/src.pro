include(../defaults.pri)

# Add more folders to ship with the application, here
folder_01.source = qml/perc
folder_01.target = qml
DEPLOYMENTFOLDERS = folder_01

# Additional import path used to resolve QML modules in Creator's code model
QML_IMPORT_PATH =

# If your application uses the Qt Mobility libraries, uncomment the following
# lines and add the respective components to the MOBILITY variable.
# CONFIG += mobility
# MOBILITY +=

# The .cpp file which was generated for your project. Feel free to hack it.
SOURCES += main.cpp \
    game/game.cpp \
    percolation/percolationsystem.cpp \
    gameobject/gameobject.cpp \
    components/physicscomponent.cpp \
    components/graphicscomponent.cpp \
    components/gameobjectcomponent.cpp \
    percolation/cluster.cpp

# Installation path
# target.path =

# Please do not modify the following two lines. Required for deployment.
include(qtquick2applicationviewer/qtquick2applicationviewer.pri)
qtcAddDeployment()

HEADERS += \
    game/game.h \
    percolation/percolationsystem.h \
    gameobject/gameobject.h \
    components/physicscomponent.h \
    components/graphicscomponent.h \
    components/gameobjectcomponent.h \
    percolation/cluster.h

OTHER_FILES += \
    qml/perc/GameView.qml
