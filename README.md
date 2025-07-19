[![White Dream](https://i.imgur.com/Fwih1xN.gif)](#) 
### Это ответление старой версии сборки проекта White Dream (old Aleph) по игре [Space Station 13]
## Быстрый старт
1. Требования
	* Для сборки проекта необходим [BYOND](https://www.byond.com/download/).
2. Сборка и запуск
	* Отклонировать/скачать данный репозиторий и запустить `BUILD.cmd`.
	* Для поднятия локального сервера, запустите `server.cmd` из директории `bin`.

* Пользователям Ubuntu/Debian:
	```bash
	git clone https://github.com/frosty-dev/white && cd white

	# Сборка библиотеки rust-g
	sudo dpkg --add-architecture i386
	sudo apt update || true
	sudo apt install -o libssl1.1:i386
	bash tools/ci/install_rust_g.sh

	# Установка BYOND и запуск сервера
	bash tools/ci/install_byond.sh
	source $HOME/BYOND/byond/bin/byondsetup
	tools/build/build
	bash tools/ci/run_server.sh
	```
## Сообщество

[<img src="https://i.imgur.com/lOHdByt.png" alt="Discord" width="150" align="left">](https://discord.gg/HezPjVQjHS)
**Наш Discord-сервер.**<br>Общение космонавтов. Основная конференция посвящённая White Dream SS13.

## Полезное
[<img src="https://i.imgur.com/ZOxkRtD.png" alt="Upstream" width="150" align="left">](https://github.com/tgstation/tgstation)
**Наш Upstream. Ничего особенного.**<br>Основная часть обновлений берётся отсюда.

[<img src="https://i.imgur.com/uCDQuc4.png" alt="Редактор карт" width="150" align="left">](https://github.com/SpaiR/StrongDMM/releases)
**Наш основной инструмент для работы с картами.**<br>Экономит кучу времени, заменяя встроенный редактор практически полностью.

## Лицензия

Весь код после [коммита 333c566b88108de218d882840e61928a9b759d8f на 2014/31/12 в 4:38 PM PST](https://github.com/frosty-dev/white-dream-main/commit/333c566b88108de218d882840e61928a9b759d8f) лицензирован под [GNU AGPL v3](https://www.gnu.org/licenses/agpl-3.0.html).

Весь код до [commit 333c566b88108de218d882840e61928a9b759d8f на 2014/31/12 в 4:38 PM PST](https://github.com/frosty-dev/white-dream-main/commit/333c566b88108de218d882840e61928a9b759d8f) лицензирован под [GNU GPL v3](https://www.gnu.org/licenses/gpl-3.0.html).
(Включая папку tools, но только если их readme не сообщает обратное)

Смотрите LICENSE и GPLv3.txt за подробностями.

TGS DMAPI API лицензирован как подпроект под MIT лицензией.

Посмотрите в самый низ [code/__DEFINES/tgs.dm](./code/__DEFINES/tgs.dm) и [code/modules/tgs/LICENSE](./code/modules/tgs/LICENSE) для MIT лицензии.

Все ассеты включая иконки и звуки лицензированы под [Creative Commons 3.0 BY-SA license](https://creativecommons.org/licenses/by-sa/3.0/), если это не обозначено где-то ещё.

Опубликованный русскоязычный текст в коде находится под лицензией [Creative Commons 4.0 BY-NC-SA license](https://creativecommons.org/licenses/by-nc-sa/4.0/), если это не обозначено где-то ещё. Это подразумевает под собой то, что использование нашего перевода где-либо ещё требует наличие данной авторской лицензии (включая всех авторов, которые когда-либо вносили правки) и отметки о том, что было изменено.
