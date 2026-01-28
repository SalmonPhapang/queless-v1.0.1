-- Create user_fcm_tokens table
create table if not exists public.user_fcm_tokens (
  user_id uuid references auth.users(id) on delete cascade not null,
  token text not null,
  created_at timestamp with time zone default timezone('utc'::text, now()) not null,
  updated_at timestamp with time zone default timezone('utc'::text, now()) not null,
  primary key (user_id, token)
);

-- Enable RLS
alter table public.user_fcm_tokens enable row level security;

-- Create policies
create policy "Users can view their own tokens"
  on public.user_fcm_tokens for select
  using (auth.uid() = user_id);

create policy "Users can insert their own tokens"
  on public.user_fcm_tokens for insert
  with check (auth.uid() = user_id);

create policy "Users can update their own tokens"
  on public.user_fcm_tokens for update
  using (auth.uid() = user_id);
