[
  {
    "table_name": "blacklists",
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "nextval('blacklists_id_seq'::regclass)"
  },
  {
    "table_name": "blacklists",
    "column_name": "specialist_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "blacklists",
    "column_name": "blacklisted_user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "blacklists",
    "column_name": "reason",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "blacklists",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "chat_messages",
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "nextval('chat_messages_id_seq'::regclass)"
  },
  {
    "table_name": "chat_messages",
    "column_name": "sender_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "chat_messages",
    "column_name": "receiver_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "chat_messages",
    "column_name": "message",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "chat_messages",
    "column_name": "timestamp",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "chat_messages",
    "column_name": "read",
    "data_type": "boolean",
    "is_nullable": "YES",
    "column_default": "false"
  },
  {
    "table_name": "complaints",
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "nextval('complaints_id_seq'::regclass)"
  },
  {
    "table_name": "complaints",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "complaints",
    "column_name": "service_id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "complaints",
    "column_name": "description",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "complaints",
    "column_name": "status",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": "'open'::text"
  },
  {
    "table_name": "complaints",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "contracts",
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "nextval('contracts_id_seq'::regclass)"
  },
  {
    "table_name": "contracts",
    "column_name": "order_id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "contracts",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "contracts",
    "column_name": "content",
    "data_type": "jsonb",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "contracts",
    "column_name": "signed_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "documents",
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "nextval('documents_id_seq'::regclass)"
  },
  {
    "table_name": "documents",
    "column_name": "specialist_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "documents",
    "column_name": "file_url",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "documents",
    "column_name": "name",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "documents",
    "column_name": "description",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "documents",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "orders",
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "nextval('orders_id_seq'::regclass)"
  },
  {
    "table_name": "orders",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "orders",
    "column_name": "specialist_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "orders",
    "column_name": "service_id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "orders",
    "column_name": "status",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "orders",
    "column_name": "contract_details",
    "data_type": "jsonb",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "orders",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "orders",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "profiles",
    "column_name": "id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "profiles",
    "column_name": "role",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "profiles",
    "column_name": "photo_url",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "profiles",
    "column_name": "display_name",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "profiles",
    "column_name": "about",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "profiles",
    "column_name": "specialty",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "profiles",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "profiles",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "reviews",
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "nextval('reviews_id_seq'::regclass)"
  },
  {
    "table_name": "reviews",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "reviews",
    "column_name": "specialist_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "reviews",
    "column_name": "service_id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "reviews",
    "column_name": "rating",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "reviews",
    "column_name": "comment",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "reviews",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "saved_services",
    "column_name": "user_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "saved_services",
    "column_name": "service_id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "saved_services",
    "column_name": "saved_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "services",
    "column_name": "id",
    "data_type": "integer",
    "is_nullable": "NO",
    "column_default": "nextval('services_id_seq'::regclass)"
  },
  {
    "table_name": "services",
    "column_name": "specialist_id",
    "data_type": "uuid",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "services",
    "column_name": "name",
    "data_type": "text",
    "is_nullable": "NO",
    "column_default": null
  },
  {
    "table_name": "services",
    "column_name": "description",
    "data_type": "text",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "services",
    "column_name": "price",
    "data_type": "numeric",
    "is_nullable": "YES",
    "column_default": null
  },
  {
    "table_name": "services",
    "column_name": "created_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  },
  {
    "table_name": "services",
    "column_name": "updated_at",
    "data_type": "timestamp with time zone",
    "is_nullable": "YES",
    "column_default": "CURRENT_TIMESTAMP"
  }
]