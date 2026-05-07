require 'open3'
require 'yaml'
require 'tempfile'

# ProcedureVerifier: Validates AsciiDoc procedures as "guided exercises"
class ProcedureVerifier
  def initialize(file_path)
    @file_path = file_path
    @content = File.read(file_path)
    @results = []
  end

  def run_verification
    puts "--- Starting Procedure Validation: #{@file_path} ---"
    
    # 1. Check for Best Practices (Instructional Design)
    check_best_practices(nil)

    # 2. Extract and Process Blocks
    # Parse source blocks paired with their nearest preceding step instruction
    lines = @content.lines
    blocks = []
    i = 0
    last_step = nil

    while i < lines.length
      line = lines[i]
      if line.match(/^\.\.? .+/)
        last_step = line.strip.sub(/^\.\.?\s*/, '')
      end

      if line.match(/^\[source,(bash|terminal|yaml)/)
        type = $1
        is_example = (i > 0 && lines[i - 1].strip.match?(/^\.Example/i))
        if i + 1 < lines.length && lines[i + 1].strip == '----'
          body_lines = []
          j = i + 2
          while j < lines.length && lines[j].strip != '----'
            body_lines << lines[j]
            j += 1
          end
          unless is_example
            blocks << [last_step || '(no step description)', type, body_lines.join.strip]
          end
          i = j + 1
          next
        end
      end
      i += 1
    end

    if blocks.empty?
      puts "[ERROR] No sequential steps or source blocks found."
      return
    end

    blocks.each_with_index do |(instruction, type, content), index|
      process_step(index + 1, instruction.strip, type, content.strip)
    end

    summarize
  end

  private

  def check_best_practices(instruction)
    # Ensure no "Magic Steps" - Identify assumed knowledge
    if @content.length > 500 && !@content.include?("oc login") && !@content.include?("export")
      puts "[ADVICE] Warning: No login or environment setup found. Check for 'magic steps'."
    end
  end

  def process_step(step_num, instruction, type, content)
    puts "\n[Step #{step_num}] #{instruction}"

    case type
    when 'yaml'
      validate_yaml(content, step_num)
    when 'bash', 'terminal'
      execute_bash(content, step_num, instruction)
    end
  end

  def validate_yaml(content, step_num)
    begin
      # Lint the YAML for syntax errors
      YAML.safe_load(content)
      puts "[VALID] YAML syntax for Step #{step_num} is correct."
      
      # If it looks like a MachineConfig or K8s Resource, check if it can be 'dry-run'
      if content.include?("apiVersion:")
        Tempfile.open(['resource', '.yaml']) do |f|
          f.write(content)
          f.close
          stdout, stderr, status = Open3.capture3("oc apply -f #{f.path} --dry-run=client")
          if status.success?
            puts "[VALID] Resource logic (dry-run) passed for Step #{step_num}."
          else
            puts "[FAILURE] Resource validation failed: #{stderr}"
          end
        end
      end
    rescue Psych::SyntaxError => e
      puts "[FAILURE] YAML Syntax error in Step #{step_num}: #{e.message}"
    end
  end

  def execute_bash(command, step_num, instruction)
    command = command.gsub(/^\$ /, '')
    puts "Executing: #{command}"
    stdout, stderr, status = Open3.capture3(command)

    if status.success?
      puts "[SUCCESS] Step #{step_num} executed."
      @results << { step: step_num, status: :passed }
      
      # Flag if a verification step is found as per instructional design
      if instruction.downcase.match?(/verify|check|confirm/)
        puts "-> Verification successfully performed."
      end
    else
      puts "[FAILURE] Step #{step_num} failed: #{stderr}"
      @results << { step: step_num, status: :failed }
      exit(1) # Stop to prevent cascading errors 
    end
  end

  def summarize
    puts "\n--- Final Summary ---"
    passed = @results.count { |r| r[:status] == :passed }
    puts "Result: #{passed}/#{@results.size} steps passed."
    
    # Check if a global verification example was included
    unless @content.downcase.include?("verify")
      puts "[ADVICE] Consider adding an end-to-end verification step to this procedure."
    end
  end
end

# Execution
if ARGV.empty?
  puts "Usage: ruby verify_procedure.rb <file.adoc>"
else
  ProcedureVerifier.new(ARGV[0]).run_verification
end
