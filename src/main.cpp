#include <QtGui/QGuiApplication>
#include "src/percobject.h"
#include "src/game/game.h"
#include "src/percolation/percolationsystem.h"
#include "src/simplematerial.h"

int main(int argc, char *argv[])
{
    QGuiApplication app(argc, argv);
    qmlRegisterType<PercObject>("Perc", 1, 0, "PercObject");
    qmlRegisterType<PercolationSystem>("Perc", 1, 0, "PercolationSystem");

    Game game;

    game.start();

    return app.exec();
}
