#include "passgen.h"

#include <QApplication>

int main(int argc, char *argv[]) {
	QApplication a(argc, argv);
	PassGen w;
	w.show();
	return a.exec();
}
