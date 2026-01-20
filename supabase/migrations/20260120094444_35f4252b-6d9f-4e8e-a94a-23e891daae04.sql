-- Create lessons table for always-repeating lessons
CREATE TABLE public.lessons (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    teacher_name TEXT,
    weekdays INTEGER[] NOT NULL, -- Array of weekday numbers (0=Sunday, 1=Monday, etc.)
    start_time TIME NOT NULL,
    end_time TIME, -- Optional end time
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE, -- Optional end date (null = forever)
    location_type TEXT NOT NULL DEFAULT 'online' CHECK (location_type IN ('online', 'in_person')),
    location_details TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Create lesson exceptions table (for single-occurrence edits/deletes)
CREATE TABLE public.lesson_exceptions (
    id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
    lesson_id UUID NOT NULL REFERENCES public.lessons(id) ON DELETE CASCADE,
    exception_date DATE NOT NULL,
    is_deleted BOOLEAN NOT NULL DEFAULT false,
    -- Override fields (null means use parent lesson values)
    title TEXT,
    teacher_name TEXT,
    start_time TIME,
    end_time TIME,
    location_type TEXT CHECK (location_type IN ('online', 'in_person')),
    location_details TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now(),
    UNIQUE(lesson_id, exception_date)
);

-- Enable Row Level Security
ALTER TABLE public.lessons ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.lesson_exceptions ENABLE ROW LEVEL SECURITY;

-- RLS Policies for lessons
CREATE POLICY "Users can view their own lessons" 
ON public.lessons FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own lessons" 
ON public.lessons FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own lessons" 
ON public.lessons FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own lessons" 
ON public.lessons FOR DELETE 
USING (auth.uid() = user_id);

-- RLS Policies for lesson_exceptions (via lesson ownership)
CREATE POLICY "Users can view their lesson exceptions" 
ON public.lesson_exceptions FOR SELECT 
USING (EXISTS (
    SELECT 1 FROM public.lessons 
    WHERE lessons.id = lesson_exceptions.lesson_id 
    AND lessons.user_id = auth.uid()
));

CREATE POLICY "Users can create lesson exceptions" 
ON public.lesson_exceptions FOR INSERT 
WITH CHECK (EXISTS (
    SELECT 1 FROM public.lessons 
    WHERE lessons.id = lesson_exceptions.lesson_id 
    AND lessons.user_id = auth.uid()
));

CREATE POLICY "Users can update their lesson exceptions" 
ON public.lesson_exceptions FOR UPDATE 
USING (EXISTS (
    SELECT 1 FROM public.lessons 
    WHERE lessons.id = lesson_exceptions.lesson_id 
    AND lessons.user_id = auth.uid()
));

CREATE POLICY "Users can delete their lesson exceptions" 
ON public.lesson_exceptions FOR DELETE 
USING (EXISTS (
    SELECT 1 FROM public.lessons 
    WHERE lessons.id = lesson_exceptions.lesson_id 
    AND lessons.user_id = auth.uid()
));

-- Create updated_at trigger
CREATE OR REPLACE FUNCTION public.update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_lessons_updated_at
BEFORE UPDATE ON public.lessons
FOR EACH ROW
EXECUTE FUNCTION public.update_updated_at_column();