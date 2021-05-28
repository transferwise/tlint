package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"

	"github.com/transferwise/tlint/version"

	"github.com/logrusorgru/aurora"
)

type rootCmd struct {
	verbose bool
}

type propertiesCmd struct {
	filename string
}

func main() {
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))
	i := &rootCmd{}
	rootCmd := &cobra.Command{
		Use:   "tlint",
		Short: "tlint is a command line tool for linting",
		Run: func(cmd *cobra.Command, args []string) {
			if len(args) == 0 {
				cmd.Help()
				os.Exit(0)
			}
		},
	}
	rootCmd.PersistentFlags().BoolVarP(&i.verbose, "verbose", "v", false, "Verbose output")

	out := rootCmd.OutOrStdout()
	log.SetOutput(out)

	rootCmd.AddCommand(newVersionCmd(), newPropertiesLintCmd(i))

	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}

func newPropertiesLintCmd(r *rootCmd) *cobra.Command {
	c := &propertiesCmd{}
	propertiesLintCmd := &cobra.Command{
		Use:   "properties",
		Short: "Validate properties files",
		Run: func(cmd *cobra.Command, args []string) {
			info, err := os.Stat(c.filename)
			if err != nil {
				log.Fatal(err)
			}
			ec := 0
			if info.IsDir() {
				files, err := filePathWalkDir(c.filename)
				if err != nil {
					log.Fatal(err)
				}

				for _, fi := range files {
					if r.verbose {
						fmt.Println(aurora.Cyan("Processing file: " + fi))
					}
					err = processFile(fi)
					if err != nil {
						ec++
						log.Println(err)
					}
				}
			}
			if ec > 0 {
				log.Fatal(fmt.Errorf("Validation failed with %d errors", ec))
			}
		},
	}
	propertiesLintCmd.PersistentFlags().StringVarP(&c.filename, "filename", "f", ".", "File name or directory")
	return propertiesLintCmd
}

func newVersionCmd() *cobra.Command {
	versionCmd := &cobra.Command{
		Use:   "version",
		Short: "Print the version number of tlint",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("tlint command tool version '%s'\n", version.VERSION)
		},
	}
	return versionCmd
}

func filePathWalkDir(root string) ([]string, error) {
	var files []string
	err := filepath.Walk(root, func(path string, info os.FileInfo, err error) error {
		if !info.IsDir() && filepath.Ext(info.Name()) == ".properties" {
			files = append(files, path)
		}
		return nil
	})
	return files, err
}

func processFile(path string) error {
	file, err := os.Open(path)
	if err != nil {
		return err
	}
	defer file.Close()

	scanner := bufio.NewScanner(file)
	ln := 0
	ec := 0
	dups := make(map[string]int)
	for scanner.Scan() {
		ln++
		line := strings.TrimSpace(scanner.Text())
		if !strings.HasPrefix(line, "#") && len(line) > 0 {
			if !strings.Contains(line, "=") {
				ec++
				log.Println(aurora.Red(fmt.Sprintf("  [%s] Missing equals sign on line %d", path, ln)))
				continue
			}

			kv := strings.Split(line, "=")
			//Now that we have the key, put it in the counting array
			_, ok := dups[kv[0]]
			if ok {
				dups[kv[0]] += 1
			} else {
				dups[kv[0]] = 0
			}

			if strings.HasSuffix(kv[0], " ") || strings.HasPrefix(kv[1], " ") {
				ec++
				log.Println(aurora.Red(fmt.Sprintf("  [%s] Separator should not be surrounded by spaces on line %d", path, ln)))
				continue
			}

			if strings.Contains(kv[0], " ") {
				ec++
				log.Println(aurora.Red(fmt.Sprintf("  [%s] Key contains space(s) on line %d", path, ln)))
				continue
			}

			if strings.HasPrefix(kv[1], "'") && strings.HasSuffix(kv[1], "'") {
				ec++
				log.Println(aurora.Red(fmt.Sprintf("  [%s] Value is surrounded by single quotes on line %d", path, ln)))
				continue
			}

			if strings.HasPrefix(kv[1], "\"") && strings.HasSuffix(kv[1], "\"") {
				ec++
				log.Println(aurora.Red(fmt.Sprintf("  [%s] Value is surrounded by double quotes on line %d", path, ln)))
				continue
			}
		}
	}

	for k, v := range dups {
		if v > 0 {
			ec++
			log.Println(aurora.Red(fmt.Sprintf("  [%s] Key '%s' has %d duplicates", path, k, v)))
		}
	}

	if err := scanner.Err(); err != nil {
		return err
	}

	if ec > 0 {
		return fmt.Errorf("Found %d errors in %s", ec, path)
	}
	return nil
}
