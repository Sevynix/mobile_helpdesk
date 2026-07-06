CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TYPE user_role AS ENUM ('admin', 'helpdesk', 'user');
CREATE TYPE ticket_status AS ENUM ('open', 'assign', 'on_progress', 'close');

CREATE TABLE users (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE tickets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    assigned_helpdesk_id UUID REFERENCES users(id) ON DELETE SET NULL,
    title VARCHAR(255) NOT NULL,
    description TEXT NOT NULL,
    status ticket_status NOT NULL DEFAULT 'open',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    closed_at TIMESTAMP WITH TIME ZONE
);

CREATE TABLE ticket_attachments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    file_path TEXT NOT NULL,
    file_type VARCHAR(50),
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE ticket_status_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    from_status ticket_status,
    to_status ticket_status NOT NULL,
    changed_by_user_id UUID NOT NULL REFERENCES users(id) ON DELETE SET NULL,
    changed_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE ticket_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    ticket_id UUID NOT NULL REFERENCES tickets(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    comment_text TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    ticket_id UUID REFERENCES tickets(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER PUBLICATION supabase_realtime ADD TABLE notifications;

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tickets_updated_at
    BEFORE UPDATE ON tickets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

CREATE OR REPLACE FUNCTION log_new_ticket()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO ticket_status_history (ticket_id, from_status, to_status, changed_by_user_id, changed_at)
    VALUES (NEW.id, NULL, 'open', NEW.user_id, now());
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER trigger_log_new_ticket
    AFTER INSERT ON tickets
    FOR EACH ROW
    EXECUTE FUNCTION log_new_ticket();

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, name, email, role, is_active)
  VALUES (
    NEW.id, 
    COALESCE(NEW.raw_user_meta_data->>'name', 'Unknown User'), 
    NEW.email, 
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'user'::user_role), 
    true
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

CREATE OR REPLACE FUNCTION assign_ticket(p_ticket_id UUID, p_helpdesk_id UUID)
RETURNS JSON AS $$
DECLARE
    v_ticket tickets%ROWTYPE;
    v_actor_role user_role;
    v_actor_id UUID;
BEGIN
    v_actor_id := auth.uid();
    
    SELECT role INTO v_actor_role FROM users WHERE id = v_actor_id;
    IF v_actor_role != 'admin' THEN
        RAISE EXCEPTION 'Hanya admin yang dapat meng-assign tiket';
    END IF;

    SELECT * INTO v_ticket FROM tickets WHERE id = p_ticket_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tiket tidak ditemukan';
    END IF;

    IF v_ticket.status != 'open' THEN
        RAISE EXCEPTION 'Tiket hanya bisa di-assign dari status OPEN';
    END IF;

    UPDATE tickets
    SET status = 'assign',
        assigned_helpdesk_id = p_helpdesk_id,
        updated_at = now()
    WHERE id = p_ticket_id;

    INSERT INTO ticket_status_history (ticket_id, from_status, to_status, changed_by_user_id)
    VALUES (p_ticket_id, 'open', 'assign', v_actor_id);

    INSERT INTO notifications (user_id, ticket_id, message)
    VALUES (p_helpdesk_id, p_ticket_id, 'Anda telah di-assign ke tiket baru.');

    INSERT INTO notifications (user_id, ticket_id, message)
    VALUES (v_ticket.user_id, p_ticket_id, 'Tiket Anda telah di-assign ke helpdesk.');

    RETURN json_build_object('success', true, 'message', 'Tiket berhasil di-assign');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION start_ticket(p_ticket_id UUID)
RETURNS JSON AS $$
DECLARE
    v_ticket tickets%ROWTYPE;
    v_actor_id UUID;
BEGIN
    v_actor_id := auth.uid();

    SELECT * INTO v_ticket FROM tickets WHERE id = p_ticket_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tiket tidak ditemukan';
    END IF;

    IF v_ticket.assigned_helpdesk_id != v_actor_id THEN
        RAISE EXCEPTION 'Anda bukan helpdesk yang ditugaskan untuk tiket ini';
    END IF;

    IF v_ticket.status != 'assign' THEN
        RAISE EXCEPTION 'Tiket hanya bisa dimulai dari status ASSIGN';
    END IF;

    UPDATE tickets
    SET status = 'on_progress',
        updated_at = now()
    WHERE id = p_ticket_id;

    INSERT INTO ticket_status_history (ticket_id, from_status, to_status, changed_by_user_id)
    VALUES (p_ticket_id, 'assign', 'on_progress', v_actor_id);

    INSERT INTO notifications (user_id, ticket_id, message)
    VALUES (v_ticket.user_id, p_ticket_id, 'Tiket Anda sedang dikerjakan oleh helpdesk.');

    RETURN json_build_object('success', true, 'message', 'Tiket berhasil dimulai');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION finish_ticket(p_ticket_id UUID)
RETURNS JSON AS $$
DECLARE
    v_ticket tickets%ROWTYPE;
    v_actor_id UUID;
BEGIN
    v_actor_id := auth.uid();

    SELECT * INTO v_ticket FROM tickets WHERE id = p_ticket_id FOR UPDATE;
    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tiket tidak ditemukan';
    END IF;

    IF v_ticket.assigned_helpdesk_id != v_actor_id THEN
        RAISE EXCEPTION 'Anda bukan helpdesk yang ditugaskan untuk tiket ini';
    END IF;

    IF v_ticket.status != 'on_progress' THEN
        RAISE EXCEPTION 'Tiket hanya bisa diselesaikan dari status ON_PROGRESS';
    END IF;

    UPDATE tickets
    SET status = 'close',
        closed_at = now(),
        updated_at = now()
    WHERE id = p_ticket_id;

    INSERT INTO ticket_status_history (ticket_id, from_status, to_status, changed_by_user_id)
    VALUES (p_ticket_id, 'on_progress', 'close', v_actor_id);

    INSERT INTO notifications (user_id, ticket_id, message)
    VALUES (v_ticket.user_id, p_ticket_id, 'Tiket Anda telah selesai ditangani.');

    RETURN json_build_object('success', true, 'message', 'Tiket berhasil diselesaikan');
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE tickets ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_attachments ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_status_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE ticket_comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Semua pengguna dapat melihat data pengguna" ON users FOR SELECT USING (auth.uid() IS NOT NULL);
CREATE POLICY "Admin dapat mengupdate user" ON users FOR UPDATE USING (
    (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
);

CREATE POLICY "Akses baca tiket" ON tickets FOR SELECT USING (
    auth.uid() IS NOT NULL AND (
        (SELECT role FROM users WHERE id = auth.uid()) = 'admin'
        OR
        user_id = auth.uid()
        OR
        assigned_helpdesk_id = auth.uid()
    )
);

CREATE POLICY "Buat tiket" ON tickets FOR INSERT WITH CHECK (
    auth.uid() = user_id
);

CREATE POLICY "Update tiket dilarang langsung" ON tickets FOR UPDATE USING (false) WITH CHECK (false);

CREATE POLICY "Baca history tiket" ON ticket_status_history FOR SELECT USING (
    EXISTS (SELECT 1 FROM tickets WHERE id = ticket_id)
);
CREATE POLICY "Tolak modifikasi history" ON ticket_status_history FOR INSERT WITH CHECK (false);
CREATE POLICY "Tolak update history" ON ticket_status_history FOR UPDATE USING (false);

CREATE POLICY "Baca komentar" ON ticket_comments FOR SELECT USING (
    EXISTS (SELECT 1 FROM tickets WHERE id = ticket_id)
);
CREATE POLICY "Tulis komentar" ON ticket_comments FOR INSERT WITH CHECK (
    auth.uid() = user_id AND 
    EXISTS (SELECT 1 FROM tickets WHERE id = ticket_id)
);

CREATE POLICY "Baca notifikasi sendiri" ON notifications FOR SELECT USING (
    auth.uid() = user_id
);
CREATE POLICY "Update notifikasi sendiri" ON notifications FOR UPDATE USING (
    auth.uid() = user_id
);
CREATE POLICY "Tolak buat notifikasi langsung" ON notifications FOR INSERT WITH CHECK (false);
