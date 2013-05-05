SRC_DIR = $$PWD/src
INCLUDEPATH += $$PWD

LIBS += -larmadillo

DEFINES += ARMA_NO_DEBUG

QMAKE_CXXFLAGS += -std=c++0x
