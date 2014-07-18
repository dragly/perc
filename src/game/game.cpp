#include "game.h"

#include <QQuickItem>
#include <QQmlContext>
#include <QDebug>

#include <src/percolation/percolationsystem.h>
//#include <src/percolation/percolationsystemgraphics.h>

Game::Game() :
    m_gameScene(NULL)
{
    m_viewer.setSurfaceType(QSurface::OpenGLSurface);
    QSurfaceFormat format;
    format.setSamples(0);
    m_viewer.setFormat(format);
    m_viewer.setMainQmlFile(QStringLiteral("qml/perc/main.qml"));


//    m_gameScene = m_viewer.rootObject()->findChild<QQuickItem*>("gameScene");
//    if(m_gameScene) {
//        m_gameScene->setProperty("color", "black");
//    } else {
//        qCritical() << "Failed to load gameScene from QML to C++";
//        exit(0);
//    }

//    PercolationSystemGraphics *percolationGraphics = new PercolationSystemGraphics(&m_percolationSystem, m_gameScene, m_viewer.engine());
//    m_percolationSystem.setPercolationSystemGraphics(percolationGraphics);

//    m_advanceTimer.setInterval(10);
//    connect(&m_advanceTimer, SIGNAL(timeout()), SLOT(advance()));
}

void Game::start()
{
    m_viewer.showFullScreen();
//    m_percolationSystem.initialize(10,10, 0.5);
//    m_viewer.showExpanded();

//    m_advanceTimer.start();
}

void Game::advance() {

}
