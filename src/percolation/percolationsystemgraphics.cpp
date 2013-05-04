#include "percolationsystemgraphics.h"

#include <src/percolation/percolationsystem.h>

#include <armadillo>
#include <iostream>

using namespace arma;
using namespace std;

/*!
 * \brief PercolationSystemGraphics::PercolationSystemGraphics test
 * \param percolationSystem
 * \param gameScene
 */
PercolationSystemGraphics::PercolationSystemGraphics(PercolationSystem* percolationSystem, QQuickItem *gameScene, QQmlEngine *engine) :
    QObject(gameScene)
{
    m_percolationSystem = percolationSystem;
    m_gameScene = gameScene;
    m_qmlEngine = engine;
}

void PercolationSystemGraphics::initialize() {
    QQmlComponent matrixComponent(m_qmlEngine, QUrl::fromLocalFile("qml/perc/PercolationMatrix.qml"));
    QObject *myObject = matrixComponent.create();
    QQuickItem *item = qobject_cast<QQuickItem*>(myObject);
    item->setParentItem(m_gameScene);
    m_percolationMatrix = item;

    const umat& occupationMatrix = m_percolationSystem->occupationMatrix();
    m_percolationMatrix->setProperty("nRows", occupationMatrix.n_rows);
    m_percolationMatrix->setProperty("nCols", occupationMatrix.n_cols);
    for(uint i = 0; i < occupationMatrix.n_rows; i++) {
        for(uint j = 0; j < occupationMatrix.n_cols; j++) {
            cout << occupationMatrix.at(i,j);
        }
    }
}
