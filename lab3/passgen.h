#ifndef PASSGEN_H
#define PASSGEN_H

#include <QWidget>

class QSpinBox;
class QCheckBox;
class QLineEdit;
class QPushButton;

class PassGen: public QWidget {
	Q_OBJECT
	
public:
	PassGen(QWidget *parent = nullptr);
	~PassGen();
	
private slots:
	void onGenerateClicked();
	void onCopyClicked();
	
private:
	QSpinBox *lengthSpinBox;
	QCheckBox *numbersCheckBox;
	QCheckBox *specialsCheckBox;
	QLineEdit *passwordLineEdit;
	QPushButton *genereteButton;
	QPushButton *copyButton;
};
#endif
