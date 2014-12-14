#include <QtGui/QGuiApplication>
#include "src/game/game.h"
#include "src/percolation/percolationsystem.h"
#include "src/simplematerial.h"
#include "src/grids/occupationgrid.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    qmlRegisterType<PercolationSystem>("org.dragly.perc", 1, 0, "PercolationSystem");
    qmlRegisterType<OccupationGrid>("org.dragly.perc", 1, 0, "OccupationGrid");
//    qmlRegisterType<Item>("org.dragly.perc", 1, 0, "SimpleMaterial");

    Game game;

    game.start();

    return app.exec();
}
