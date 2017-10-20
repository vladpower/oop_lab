#!/usr/bin/env ruby
require 'csv'

class University
    attr_reader :name
    attr_reader :passing_score
    attr_reader :max_count_students

    # Create the object
    def initialize(attributes = {})
      @name = attributes[:name]
      @passing_score = attributes[:passing_score]
      @max_count_students = attributes[:max_count_students]
      @listStudents = []
    end

    def apply_student(student)
        if student.academic_performance >= @passing_score && @listStudents.count() < @max_count_students then
            accept_student student
        end
    end

    def expel_student(student)
        @listStudents.delete student
        student.university = nil
        student.penalty = 0
    end

    def show_students()
        puts " "
        puts "University #{name} (#{@listStudents.length}):"
        @listStudents.each do |s|
            puts "#{s.name} #{s.surname} #{s.academic_performance} #{s.penalty} #{s.course}"
        end
    end

    private def accept_student(student)
        @listStudents.push student
        student.university = self
        student.course = 1
    end

    

end

class Student
    attr_reader :male #bool
    attr_reader :name
    attr_reader :surname
    attr_accessor :university
    attr_accessor :academic_performance
    attr_accessor :course
    attr_accessor :penalty
    attr_accessor :finished #bool

    # Create the object
    def initialize(attributes = {})
        @male = attributes[:male]
        @name = attributes[:name]
        @surname = attributes[:surname]
        @penalty = 0
        @finished = false
        @course = 0
    end

    def studying?
        @university
    end

    def passed?
        @academic_performance >= @university.passing_score
    end

    def failed?
        !passed?
    end

    def exam() # gaussian distribution
        value = 0
        12.times do
            value+=rand();
        end
        value-=6;
        score = (15*value+65).to_int
        if score > 100 then score = 100 end
        if score < 0 then score = 0 end
        @academic_performance = score
    end

    def choose_universities(univers)
        univers.sample(3)
    end

    def try_enroll(univer)
        if !studying?
            univer.apply_student self
        end
    end

    def drop_out()
        if studying?
            university.expel_student self
        end
    end

    def check_performance()
        if passed?
            @penalty = 0
        else
            @penalty += 1
            if penalty >= 3
                drop_out
            end
        end
    end

    def next_course
        if @course < 4
            @course += 1
        else
            @finished = true
            drop_out
        end
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

    def self.rand_student
        m = [true, false].sample
        n = m ? rand_male_name : rand_female_name
        s =  m ? rand_male_surname : rand_female_surname
        Student.new(male: m, name: n, surname: s)
    end
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
students = Array.new(student_count) {Randomizer.rand_student()}

simulated_time.times do |t| # mounths

    students.each do |s|
        if s.studying?
            if (t % 3) == 0
                s.exam
                s.check_performance
            else
                if s.failed?
                    s.exam
                    s.check_performance
                end
            end
            if (t % 12) == 0 && s.studying?
                s.next_course
            end

        else
            if (t % 12) == 0
                s.exam
                choosen_univers = s.choose_universities univers
                choosen_univers.each do |u|
                    s.try_enroll u
                end
            end
        end

        #puts "#{s.name} #{s.surname} #{s.academic_performance}"
    end
    puts "\n#{t+1} месяц:"
    univers.each do |u|
        u.show_students
    end

end
