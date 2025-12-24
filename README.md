# profi

- [ ] страница регистрации и авторизации (пользователь, войти без регистрации, специалист, админ)
      специалист параметры: фотография, отображаемое имя, пароль, подтверждение пароля, о себе, специальность 
      пользователь параметры: фотография, отображаемое имя, пароль, подтверждение пароля
      пользователь без регистрации: чисто зайти
- [ ] реализовать таббары для каждой из ролей
	  специалист: услуги, чаты, профиль, заказы 
	  незарегистрированый и обычный пользователь: главная, сохраненные, профиль, чаты
	  общие страницы (вне таббара, в эпбаре): настройки
- [ ] описание каждого таба:
	 специалист:
		  услуги: список всех созданных услуг, создание услуг, поиск, фильтрация
		  чаты: стандартные чаты с заказчиками
		  профиль: отображение всех данных профиля с последующим редактированием + закрепление документов 
		  заказы: режим перечень верифицированных заказов, режим верификация заказов (одобрение/отклонение), режим черный список заказчиков
	 пользовтель:
		 главная: поиск нужной услуги, перечень услуг, фильтры
		 сохраненные: поиск нужной услуги, перечень сохраненных услуг, фильтры
		 профиль: тображение всех данных профиля с последующим редактированием 
		 чаты: чаты с специалистами 

Техническое задание: необходимо разработать мобильное приложение продвижения профессиональных наемных рабочих и их услуг. Для администратора реализовать функционал введения базы данных. Для профессионального рабочего реализовать функционал: создание заявки на регистрацию рабочего и его услуг; закрепление документов в профиле; редактирование услуг работника; просмотр заявок на заказ с последующим одобрением/отказом; редактирование информации в составляемом договоре; редактирование черного списка. Для пользователя реализовать функционал: ленты рекомендаций услуг рабочих, фильтрацию и поиск услуг и рабочих, оставление отзывов под рабочим с ссылкой на конкретную услугу, хранение договоров на услугу в личном кабинете, редактирование профиля, отправка жалоб на конкретную услугу, выставление рейтинга услуги, регистрация личного кабинета в системе.

структура бд:
[auth.users] (встроенная Supabase auth)
- id (UUID, PK)
- email
- password_hash
- confirmed_at
 |
 | (1:1 foreign key on id)
 v
[profiles]
- id (UUID, PK, FK to auth.users.id)
- role (ENUM: 'user', 'specialist', 'admin')
- photo_url (TEXT)
- display_name (TEXT)
- about (TEXT, NULL for non-specialists)
- specialty (TEXT, NULL for non-specialists)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

   | (1:N, specialist_id)
   v
[services]
- id (SERIAL, PK)
- specialist_id (UUID, FK to profiles.id)
- name (TEXT)
- description (TEXT)
- price (NUMERIC)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

   | (1:N, service_id)
   v
[orders]
- id (SERIAL, PK)
- user_id (UUID, FK to profiles.id)
- specialist_id (UUID, FK to profiles.id)
- service_id (INT, FK to services.id)
- status (ENUM: 'pending', 'approved', 'rejected', 'verified')
- contract_details (JSONB, for editable contract info)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

   | (1:N, specialist_id)
   v
[documents]
- id (SERIAL, PK)
- specialist_id (UUID, FK to profiles.id)
- file_url (TEXT, Supabase Storage)
- name (TEXT)
- description (TEXT)
- created_at (TIMESTAMP)

   | (N:N via junction)
   v
[saved_services] (junction table for users' saved services)
- user_id (UUID, FK to profiles.id, PK composite)
- service_id (INT, FK to services.id, PK composite)
- saved_at (TIMESTAMP)

   | (1:N, specialist_id or user_id)
   v
[chat_messages]
- id (SERIAL, PK)
- sender_id (UUID, FK to profiles.id)
- receiver_id (UUID, FK to profiles.id)
- message (TEXT)
- timestamp (TIMESTAMP)
- read (BOOLEAN, default FALSE)

   | (1:N, specialist_id)
   v
[blacklists]
- id (SERIAL, PK)
- specialist_id (UUID, FK to profiles.id)
- blacklisted_user_id (UUID, FK to profiles.id)
- reason (TEXT)
- created_at (TIMESTAMP)

   | (1:N, service_id)
   v
[reviews]
- id (SERIAL, PK)
- user_id (UUID, FK to profiles.id)
- specialist_id (UUID, FK to profiles.id)
- service_id (INT, FK to services.id)
- rating (INT, 1-5)
- comment (TEXT)
- created_at (TIMESTAMP)

   | (1:N, service_id)
   v
[complaints]
- id (SERIAL, PK)
- user_id (UUID, FK to profiles.id)
- service_id (INT, FK to services.id)
- description (TEXT)
- status (ENUM: 'open', 'resolved')
- created_at (TIMESTAMP)

   | (1:N, order_id)
   v
[contracts] (stored contracts for users)
- id (SERIAL, PK)
- order_id (INT, FK to orders.id)
- user_id (UUID, FK to profiles.id)
- content (JSONB or TEXT, for stored/editable contract)
- signed_at (TIMESTAMP)
