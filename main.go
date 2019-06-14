package main

import (
	"fmt"
	"log"
	"os"

	"github.com/spf13/cobra"
)

// VERSION indicates which version of the binary is running.
var VERSION string

// GITCOMMIT indicates which git hash the binary was built off of
var GITCOMMIT string

func main() {
	log.SetFlags(log.Flags() &^ (log.Ldate | log.Ltime))

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

	out := rootCmd.OutOrStdout()
	log.SetOutput(out)

	rootCmd.AddCommand(newVersionCmd(), newPropertiesLintCmd())

	if err := rootCmd.Execute(); err != nil {
		log.Fatal(err)
	}
}

func newPropertiesLintCmd() *cobra.Command {
	propertiesLintCmd := &cobra.Command{
		Use:   "properties",
		Short: "Validate properties files",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Println("Validating... done")
		},
	}
	return propertiesLintCmd
}

func newVersionCmd() *cobra.Command {
	versionCmd := &cobra.Command{
		Use:   "version",
		Short: "Print the version number of tlint",
		Run: func(cmd *cobra.Command, args []string) {
			fmt.Printf("tlint command tool %s\n", VERSION)
		},
	}
	return versionCmd
}
