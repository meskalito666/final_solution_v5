# сервис:
Сейчас сервис поднят на машине 167.235.136.60 в директории root/final_solution_v5  
Ручки доступны тут http://167.235.136.60:5020/send_query и тут http://167.235.130.89:5020/send_query  
Сервис принимает на вход post-запрос с json формата: {"query": "some_sentence"}, возвращает {"nearest_sentence": "some_sentence"}

# структура файлов:
- actions - шеллы для запуска, остановки и обновления сервисов
- api_gateway, emb_to_txt, serving - папки с сервисами
- idxs - наборы индексов 
- docker-compose.yml - файл для сборки сервисов и start.sh - шелл, который его запускает
- load_model.sh - шелл для загрузки модели

# как это завести (from scratch) и обновить:
1. пара мест, где надо поправить адрес хоста, если заводить на своей машине: /actions/build_n_deploy.sh, docker-compose.yml
2. *опционально:* скачать папку idxs с google drive(там лежат полные индексы) и заменить ею папку idxs из текущего репозитория (тут обрезаные, чтоб гитхаб не ругался) https://drive.google.com/drive/folders/1EVwWRh11iRRgTQvEJ8BmdwbR6U0cq2D8?usp=sharing
3. sudo bash load_model.sh - модель на гитхаб не влезла, поэтому скачиваем с сервера 
4. cd actions
5. ./build_n_push.sh - собираем образы и пушим в registry
6. cd ..
7. ./start.sh - стартуем сервис с помощью docker-compose 

* если нужно обновить индексы:  
   1 cd actions    
   2 sudo bash update.sh - делаем rolling-update и обновляем индексы (дилей 15сек), предусмотрен rollback в случае ошибки   

# как это работает:
1. serving - модель, принимает post запрос с json вида {"instances": ["some_sentence"]} доступна вот тут http://167.235.136.60:8501/v1/models/use_l:predict, возвращает эмбеддинг 
2. api_gateway - сервис получает запрос, отправляет его в модель для трансформации, для полученного эмбеддинга ищет ближайший кластер, отправляет эмбеддинг в сервис с найденым номером кластера, получает ответ в виде наиболее похожего запроса и возвращает его пользователю в json формата: {"nearest_sentence":"some_sentence"} 
3. emb_to_txt_n - сервисы по номерам кластеров, что получают эмбеддинг и возвращают по нему ближайший текстовый запрос 

# Контрольные вопросы
1. Точно ли вы подняли все, что нужно QA системе? Если вы закодили все внутри одного приложения, то это не зачтется :(
> qa-система работает, используется 6 сервисов 

2. Каким образом файлы с индексами попадают на целевые машины? Попадают ли индексы адресно или происходит broadcast одного файла на все сервера?
> broadcast одного файла на все сервера

3. Написали ли ли вы стратегию обновления индекса в системе? Что это за стратегия: Blue / Green или Rolling? А есть ли у вашей стратегии downtime?
> rolling с дилеем в 15 сек

4. При обновлении индекса обновляются ли необходимые параметры в других частях системы?Т.е. не случится ли такого, что gateway направляет запрос не на тот индекс если во время обновления что то пошло не так? Не забыли ли вы про идемпотентность обновлений в вашей стратегии?
> при обновлении меняется путь до нужного набора индексов, он передается в качестве переменной среды окружения для сервисов в swarm. Если обновлять индексы несколько раз с теми же параметрами - результат будет один и тот же (идемпотентность)

5. Что будет, если индекс не сможет обновиться? (например, попался битый файл индекса)
> предусмотрен rollback

6. Может, вы не поленились и предусмотрели ли какие нибудь failover?
> да, для наиболее нагруженного сервиса предусмотрена дополнительная реплика

7. Вы использовали уже готовые инструменты, знакомые многим или решили написали свой shellсипед?
> shellсипед
   
8. А что с самими приложениями сервинга? Не перегружен ли его запуск внешними зависимостями, правильно ли выключается и поднимается приложение. Существует способ быстро проверить здорово ли приложение?
> поднимается через docker-compose исправно, c зависимостями проблем не возникает, образы собираются корректно. Healthcheck предусмотрен для каждого сервиса, поднимается в compose-файле, отображается компандой docker ps -> колонка STATUS -> значение в скобках (healty)