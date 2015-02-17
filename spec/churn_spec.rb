require 'spec_helper'

describe "Churn" do
  COMMAND_NAME = 'ichurn'

  it "has a constant that stores the command name" do
    expect(Churn::COMMAND_NAME).to match(/^#{COMMAND_NAME}$/)
  end

  it "raises an exception if root_directory is not a directory" do
    directory_name = "not_a_directory"
    Churn.root_directory = directory_name
    expect { Churn.compute }.to raise_error(StandardError, "#{COMMAND_NAME}: #{directory_name}: No such file or directory")
  end

  it "count insertions and deletions" do
    expect(Churn.count_lines_from [" 1 file changed", " 2 insertions(+)", " 1 deletion(-)", " 1 file changed", " 1 insertion(+)"]).to include(insertions: 3, deletions: 1)
  end

  context "within an existing directory" do
    before(:each) do
      @directory_name = Dir.getwd + "/.." + "/churn_test_directory"
      system("mkdir #{@directory_name}")
      Churn.root_directory = @directory_name
    end

    it "has the same current directory before and after call compute" do
      cwd = Dir.getwd
      Churn.compute rescue # => no matter if there is an exception, the expectation should be met
      expect(cwd).to eq(Dir.getwd)
    end

    it "raises an exception if the root_directory is not a git repository" do
      expect { Churn.compute }.to raise_error(StandardError, "#{COMMAND_NAME}: #{@directory_name}: fatal: Not a git repository (or any of the parent directories): .git")
    end

    context "within a git repository" do
      before(:each) do
        system("git init #{@directory_name}")
        system("cd #{@directory_name} && git config user.email 'atester@ichurn.org' && git config user.name 'auto tester'")
      end

      it "raises an exception if the root_directory is a git repository with no commits" do
        expect { Churn.compute }.to raise_error(StandardError, "#{COMMAND_NAME}: #{@directory_name}: fatal: bad default revision 'HEAD'")
      end

      it "raises an exception if try to compute churn for an unknown revision" do
        file_name = "a_file"
        system("cd #{@directory_name} && touch #{file_name} && git add #{file_name} && git commit -m 'initial commit'")
        revision = "UNKNOWN_REVISION"

        expect { Churn.compute revision: revision }.to raise_error(StandardError, "#{COMMAND_NAME}: fatal: ambiguous argument '#{revision}': unknown revision or path not in the working tree.")
      end

      it "has HEAD as default revision" do
        file_name = "a_file"
        system("cd #{@directory_name} && echo 'line1' > #{file_name} && git add #{file_name} && git commit -m 'initial commit'")        
        expect(Churn.compute).to eq(Churn.compute revision: "HEAD")
      end

      it "computes the amount of inserted lines on the current branch for the entire history, all files, and default HEAD revision" do
        file_name = "a_file"
        system("cd #{@directory_name} && echo 'line1' > #{file_name} && git add #{file_name} && git commit -m 'initial commit'")
        expect(Churn.compute[:insertions]).to eq(1)
        system("cd #{@directory_name} && echo 'line1\nline2\nline3' > #{file_name} && git add #{file_name} && git commit -m 'initial commit'")
        expect(Churn.compute[:insertions]).to eq(3)

        file_name = "another_file"
        system("cd #{@directory_name} && echo 'line1' > #{file_name} && git add #{file_name} && git commit -m 'initial commit'")
        expect(Churn.compute[:insertions]).to eq(4)
        system("cd #{@directory_name} && echo 'line1\nline2' > #{file_name} && git add #{file_name} && git commit -m 'initial commit'")
        expect(Churn.compute[:insertions]).to eq(5)
      end

      it "computes the amount of deleted lines on the current branch for the entire history, all files, and default HEAD revision" do
          file_name = "a_file"
          system("cd #{@directory_name} && echo 'line1' > #{file_name} && git add #{file_name} && git commit -m 'initial commit'")
          expect(Churn.compute[:deletions]).to eq(0)
          system("cd #{@directory_name} && echo 'line2\nline3' > #{file_name} && git add #{file_name} && git commit -m 'initial commit'")
          expect(Churn.compute[:deletions]).to eq(1)

          file_name = "another_file"
          system("cd #{@directory_name} && echo 'line1\nline2' > #{file_name} && git add #{file_name} && git commit -m 'initial commit'")
          expect(Churn.compute[:deletions]).to eq(1)
          system("cd #{@directory_name} && echo 'line3' > #{file_name} && git add #{file_name} && git commit -m 'initial commit'")
          expect(Churn.compute[:deletions]).to eq(3)
      end

      it "raises an exception if the file does not exist" do
        file_name = "non-existent-file"
        system("cd #{@directory_name} && touch a_file && git add a_file && git commit -m 'initial commit'")
        expect { Churn.compute file_name: file_name}.to raise_error(StandardError, "#{COMMAND_NAME}: fatal: ambiguous argument '#{file_name}': unknown revision or path not in the working tree.")
      end

      it "computes the amount of inserted lines on a specific file on the current branch for the entire" do
        file_a = "a_file"
        system("cd #{@directory_name} && echo 'line1' > #{file_a} && git add #{file_a} && git commit -m 'initial commit'")
        system("cd #{@directory_name} && echo 'line1\nline2\nline3' > #{file_a} && git add #{file_a} && git commit -m 'initial commit'")

        file_b = "another_file"
        system("cd #{@directory_name} && echo 'line1' > #{file_b} && git add #{file_b} && git commit -m 'initial commit'")
        system("cd #{@directory_name} && echo 'line1\nline2' > #{file_b} && git add #{file_b} && git commit -m 'initial commit'")

        expect(Churn.compute(file_name: file_a)[:insertions]).to eq(3)
        expect(Churn.compute(file_name: file_b)[:insertions] ).to eq(2)
      end

      it "returns a summary of the history" do
        file_a = "a_file"
        system("cd #{@directory_name} && echo 'line1' > #{file_a} && git add #{file_a} && git commit -m 'initial commit'")
        system("cd #{@directory_name} && echo 'line2\nline3' > #{file_a} && git add #{file_a} && git commit -m 'initial commit'")
        expect(Churn.git_history_summary).to eq([" 1 file changed", " 2 insertions(+)", " 1 deletion(-)", " 1 file changed", " 1 insertion(+)"])
      end
    end

    after(:each) do
      system("rm -r -f #{@directory_name}")
    end
  end

end
