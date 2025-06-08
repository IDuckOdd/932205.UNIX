#include "passgen.h"

#include <QVBoxLayout>
#include <QHBoxLayout>
#include <QFormLayout>
#include <QSpinBox>
#include <QCheckBox>
#include <QLineEdit>
#include <QPushButton>
#include <QRandomGenerator>
#include <QClipboard>
#include <QApplication>
#include <algorithm>

PassGen::PassGen(QWidget *parent) : QWidget(parent) {
	setWindowTitle("Password Generator");
	setFixedSize(400, 200);
	
	lengthSpinBox = new QSpinBox;
	lengthSpinBox->setRange(8, 64);
	lengthSpinBox->setValue(8);
	
	numbersCheckBox = new QCheckBox("Insert Numbers(0-9)");
	numbersCheckBox->setChecked(true);
	
	specialsCheckBox = new QCheckBox("Insert symbols !@#$%");
	specialsCheckBox->setChecked(true);
	
	genereteButton = new QPushButton("Generate");
	passwordLineEdit = new QLineEdit;
	passwordLineEdit->setReadOnly(true);
	
	copyButton = new QPushButton("Copy");
	
	
	QFormLayout *settingsLayout = new QFormLayout;
	settingsLayout->addRow("Password length:", lengthSpinBox);
	settingsLayout->addRow(numbersCheckBox);
	settingsLayout->addRow(specialsCheckBox);
	
	QHBoxLayout *resultLayout = new QHBoxLayout;
	resultLayout->addWidget(passwordLineEdit);
	resultLayout->addWidget(copyButton);
	
	QVBoxLayout *mainLayout = new QVBoxLayout(this);
	mainLayout->addLayout(settingsLayout);
	mainLayout->addWidget(genereteButton);
	mainLayout->addLayout(resultLayout);
	
	connect(genereteButton, &QPushButton::clicked, this, &PassGen::onGenerateClicked);
	connect(copyButton, &QPushButton::clicked, this, &PassGen::onCopyClicked);
	
	onGenerateClicked();
}

PassGen::~PassGen(){}

void PassGen::onGenerateClicked(){
	const QString lowercase_chars = "abcdefghijklmnopqrstuvwxyz";
	const QString uppercase_chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ";
	const QString number_chars = "0123456789";
	const QString special_chars = "!@#$%^&*()_+-+[]{}|;:,.<>?";
	
	QString availableChars = lowercase_chars + uppercase_chars;
	if (numbersCheckBox->isChecked()) {
		availableChars += number_chars;
	}
	if (specialsCheckBox->isChecked()) {
		availableChars += special_chars;
	}
	
	QString password = "";
	password += lowercase_chars[QRandomGenerator::global()->bounded(lowercase_chars.length())];
	password += uppercase_chars[QRandomGenerator::global()->bounded(uppercase_chars.length())];
	
	if (numbersCheckBox->isChecked()) {
		password += number_chars[QRandomGenerator::global()->bounded(number_chars.length())];
	}
	if (specialsCheckBox->isChecked()) {
		password += special_chars[QRandomGenerator::global()->bounded(number_chars.length())];
	}
	
	int length = lengthSpinBox->value();
	for (int i = password.length(); i < length; ++i) {
		int randomIndex = QRandomGenerator::global()->bounded(availableChars.length());
		password += availableChars[randomIndex];
	}
	
	std::random_shuffle(password.begin(), password.end());
	
	passwordLineEdit->setText(password);
}

void PassGen::onCopyClicked() {
	QApplication::clipboard()->setText(passwordLineEdit->text());
}
