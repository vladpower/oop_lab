#!/usr/bin/env ruby
require 'csv'

class University
    attr_reader :name
    attr_reader :passing_score
    attr_reader :max_count_students
	attr_reader :list_students
	attr_accessor :msg_events
    # Create the object
    def initialize(attributes = {})
      @name = attributes[:name]
      @passing_score = attributes[:passing_score]
      @max_count_students = attributes[:max_count_students]
      @list_students = []
	  @list_re_exam = []
	  @msg_events = []
    end

    def apply_student(person, ege_score)
        if ege_score >= @passing_score && @list_students.count() < @max_count_students then
            accept_student person
        end
    end

    def expel_student(student)
        @list_students.delete student
		@list_re_exam.delete student
		student.expelled
    end
	
	def exam
	    list_students.each do |s|
		    if s.pass_exam > 0
			   msg_events.push "#{student_name s.person} не сдал#{fem_end s.person,"а"} экзамен, получив #{s.academic_performance}, и отправляется на переэкзаменовку."
		       @list_re_exam.push s
		    else
			   @msg_events.push "#{student_name s.person} успешно сдал#{fem_end s.person,"а"} экзамен на #{s.academic_performance}."
			end
		end
    end
	
	def re_exam
	    @list_re_exam.each do |s|
		    case s.pass_exam
			when 0
			   msg_events.push "#{student_name s.person} успешно пересдал#{fem_end s.person,"а"} экзамен на #{s.academic_performance}."
			   @list_re_exam.delete s
			when 2
			    msg_events.push "#{student_name s.person} не сдал#{fem_end s.person,"а"} экзамен во второй раз, получив #{s.academic_performance} и отправляется на переэкзаменовку."
			when 3
			    msg_events.push "#{student_name s.person} не сдал#{fem_end s.person,"а"} экзамен в третий раз, получив #{s.academic_performance}, и отчисляется за неуспеваемость."
			    expel_student s
			end
			   
		end
    end
	
	def end_year
	    @list_students.each do |s|
		    s.next_course
			if s.finished?
			   msg_events.push "#{student_name s.person} успешно закончил#{fem_end s.person,"а"} обучение."
			else
			   msg_events.push "#{student_name s.person} теперь учится на #{s.course} курсе"
			end
			
		end
	end

    private def accept_student(person)
	    student = Student.new person, self
        @list_students.push student
		person.student = student
    end

end

class Person
    attr_reader :male #bool
    attr_reader :name
    attr_reader :surname
	attr_accessor :student
	attr_accessor :finished #bool
	
	def initialize(attributes = {})
	    @male = attributes[:male]
		@name = attributes[:name]
		@surname = attributes[:surname]
		@student = nil
    end
	
	def studying?
        @student
    end
	
	
	
	def university
	    @student.university
	end
	
	def choose_universities(univers)
        univers.sample(3)
    end

    def try_enroll(univer, ege_score)
        if !studying?
            univer.apply_student self, ege_score
        end
    end

    def drop_out
        if studying?
            university.expel_student @student
        end
    end
	

	
	
end

class Student
    attr_reader   :person
    attr_accessor :academic_performance
    attr_accessor :course
    attr_accessor :penalty
	attr_reader :university
    
    def initialize(person, university)
	    @person = person
		@university = university
        @penalty = 0
        @course = 1
    end

    def passed?
        @academic_performance >= @university.passing_score
    end

    def failed?
        !passed?
    end
	
	def finished?
        @person.finished
    end

	def pass_exam #rerurn 0 if exam passed
	    @academic_performance = rand_exam
		if @academic_performance >= university.passing_score
		   @penalty = 0
		else
		   @penalty += 1
		end
	end

    def next_course
        if @course < 4
            @course += 1
        else
            @person.finished = true
        end
    end
	
	def expelled
	   @person.student = nil
	end
end


class Randomizer #static
    @@male_names = CSV.read('male_names.txt')
    @@female_names = CSV.read('female_names.txt')
    @@male_surnames = CSV.read('male_surnames.txt')
    @@female_surnames = CSV.read('female_surnames.txt')

    private_class_method :new

    def self.rand_male_name
        @@male_names.sample[0]
    end

    def self.rand_female_name
        @@female_names.sample[0]
    end

    def self.rand_male_surname
        @@male_surnames.sample[0]
    end

    def self.rand_female_surname
        @@female_surnames.sample[0]
    end

    def self.rand_person
        m = [true, false].sample
        n = m ? rand_male_name : rand_female_name
        s =  m ? rand_male_surname : rand_female_surname
        Person.new(male: m, name: n, surname: s)
    end
end

def rand_exam()
    value = 0
    12.times do
        value+=rand();
    end
    value-=6;
    score = (15*value+65).to_int
    if score > 100 then score = 100 end
    if score < 0 then score = 0 end
    score
end

def show_students(university)
    list = university.list_students
    puts " "
    puts "Университет #{university.name} (#{list.length}):"
    list.each do |s|
        puts "#{s.person.name} #{s.person.surname} #{s.academic_performance} #{s.penalty} #{s.course}"
    end
 end
 
 def show_msg_events(university)
    list = university.msg_events
	if list.count > 0
	    puts "\nСобытия в университете #{university.name}:\n"
        list.each do |e|
            puts e
        end
	    list.clear
	end
    
 end
 
 def fem_end(student,str)
    if !student.male

	    str
	end
 end
 
 def student_name(student)
    "Студент#{fem_end student,"ка"} #{student.surname} #{student.name}"
 end

print "Введите количество студентов: "
student_count = gets.to_i
print "Введите количество симулируемых месяцев: "
simulated_time = gets.to_i
univer_names = ["НГУ","ТГУ","НовГУ","СПбГУ","МГУ"]
univers = Array.new(5) {|index| University.new name: univer_names[index],
    passing_score: 50+index*5,
    max_count_students: 25
}
students = Array.new(student_count) {Randomizer.rand_person()}

simulated_time.times do |t| # mounths
    puts "\n#{t+1} месяц:"
	univers.each do |u|
	    if(t % 3) == 0
		    u.exam
		else
		    u.re_exam
		end
		if(t % 12) == 0
		    u.end_year
		end
        show_msg_events u
    end
    students.each do |s|
        if s.studying?
		    if Random.rand(200)==0 
			    puts "#{student_name s} покинул#{fem_end s,"а"} университет #{s.university.name} по собственному желанию."
			    s.drop_out
				
		    end
        else
            if (t % 12) == 0 && !s.finished
			    ege_score = rand_exam
                choosen_univers = s.choose_universities univers
                choosen_univers.each do |u|
                    s.try_enroll u, ege_score
                end
				print "#{student_name s} сдал#{fem_end s,"а"} ЕГЭ на #{ege_score} и "
				if s.studying?
				   puts "поступил#{fem_end s,"а"} в университет #{s.university.name}."
				else
				   puts "никуда не поступил#{fem_end s,"а"}"
				end
            end
        end
    end
    
	gets

end
