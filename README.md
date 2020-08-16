# minsk8

Flutter в режиме [live-code](https://www.youtube.com/playlist?list=PLMAOL6NXxmsgTUrZE4Y9xhIxzDA46X1lc). Потому что прёт! Кросс-платформенный маркетплейс на GraphQL и Firebase.

## How to start

```
$ flutter packages pub run build_runner build --delete-conflicting-outputs
```

for VSCode Apollo GraphQL

```
$ npm install -g apollo
```

create `./apollo.config.js`

```js
module.exports = {
  client: {
    includes: ['./lib/**/*.dart'],
    service: {
      name: 'minsk8',
      url: 'https://minsk8.herokuapp.com/v1/graphql',
      // optional headers
      headers: {
        'x-hasura-admin-secret': '<secret>',
        'x-hasura-role': 'user',
      },
      // optional disable SSL validation check
      skipSSLValidation: true,
      // alternative way
      // localSchemaFile: './schema.json',
    },
  },
}
```

how to download `schema.json` for `localSchemaFile`

```
$ apollo schema:download --endpoint https://minsk8.herokuapp.com/v1/graphql --header 'X-Hasura-Admin-Secret: <secret>' --header 'X-Hasura-Role: user'
```

```
cd firebase
firebase functions:config:set someservice.key="THE API KEY" someservice.id="THE CLIENT ID"
firebase deploy
```

## Why?

В редакцию пришло письмо, как говорится.

> "Извиняюсь что влезаю так поздно. Но хотел узнать, вы не рассматривали вариант работы над проектом не в одиночку? Сам около 10 лет в разработке и уже понимаю что выгорать стал, нет драйва как раньше, по факту все одно и тоже. Но для меня хорошим фактором продолжать работать является работа в команде, когда все друг друга подталкивают делать что-то, главное найти активных и близких по духу людей. К тому же, есть положительный опыт разработки в команде и запуске своего проекта, в данный момент благодаря этому живу на пассивном доходе и для меня это скорее как часть жизни а не работа. Для себя понял что одному проект тащить тяжело, слишком распыляешься и в результате нигде не успеваешь."

Это удивительно, как неожиданно возвращаются посылаемые в космос сигналы.

После кризиса среднего возраста, с удвоенной силой стремишься обрести бессмертие. Пирамида Маслова, будь она неладна. Я в разработке уже четверть века. Выгорал несколько раз от полугода до трех лет. Но возвращался обратно. Это призвание или крест.

Ещё по молодости в строительной бригаде наблюдал синергию. Само определение узнал намного позже. Сколько было безуспешных попыток найти партнера. Уверен, что вместе можно сделать в разы больше. В итоге реализовал себя в этом частично, управляя командой, работая по найму. А ещё выпустил класс учеников. Но очень много сил уходит на борьбу с ветряными мельницами.

И я придумал рецепт - это бой с тенью. Мой спарринг-партнер - трансляции на Ютубе. Записываю процесс с самого начала на камеру. Как я учил новый язык, устанавливал окружение, проектировал схему данных, формулировал задачи, проводил исследования, разрабатывал функционал. Гы-гы, уже 250 подписчиков. Были жалобы, что много воды. Не понимают, что я это делаю не на публику, а для себя.

Если MVP не рождается за 3 месяца, то энтузиазм угасает. Когда я понял, что не успеваю, решил отвлечься на трейдинг. Ох, лучше бы уехал отдыхать. С другой стороны, неудачи прибавляют энергии. Только надо заставить себя закрыть убыток, саморазрушение парализует. У меня уже истерики, чего не было очень давно.

Я убежден, что если "Just For Fan", то может родиться что-то стоящее. Когда выращиваешь с любовью и не обременяя обязательствами. Какой может быть тираж и мультипликатор успешного IT-продукта - это не надо долго объяснять, есть куда тыкать пальцем для примера. Сейчас задача минимум - запустить. А дальше уже что вырастет, то вырастет. Как минимум - ещё одна галочка в портфолио. Пускай напишут на моей могильной плите: "он пытался".
