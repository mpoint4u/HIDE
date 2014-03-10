package ;
import js.Browser;
import js.html.TextAreaElement;

/**
 * ...
 * @author AS3Boyan
 */
class Main
{
	public static var name:String = "boyan.project.haxe";
	public static var dependencies:Array<String> = ["boyan.bootstrap.new-project-dialog", "boyan.bootstrap.tab-manager", "boyan.bootstrap.project-options", "boyan.bootstrap.file-tree", "boyan.management.project-access", "boyan.codemirror.editor"];
	private static var code:String;
	private static var indexPageCode:String;
	
	//If this plugin is selected as active in HIDE, then HIDE will call this function once on load	
	public static function main():Void
	{
		HIDE.waitForDependentPluginsToBeLoaded(name, dependencies, function ():Void
		{
			NewProjectDialog.getCategory("Haxe", 1).addItem("Flash Project", createFlashProject);			
			NewProjectDialog.getCategory("Haxe").addItem("JavaScript Project", createJavaScriptProject);
			NewProjectDialog.getCategory("Haxe").addItem("Neko Project", createNekoProject);
			NewProjectDialog.getCategory("Haxe").addItem("PHP Project", createPhpProject);
			NewProjectDialog.getCategory("Haxe").addItem("C++ Project", createCppProject);
			NewProjectDialog.getCategory("Haxe").addItem("Java Project", createJavaProject);
			NewProjectDialog.getCategory("Haxe").addItem("C# Project", createCSharpProject);
			
			//NewProjectDialog.getCategory("Haxe").select();
			
			HIDE.readFile(name, "templates/Main.hx", function (data:String):Void
			{
				Browser.window.console.warn(data == "");
				
				code = data;
				
				//Notify HIDE that plugin is ready for use, so plugins that depend on this plugin can start load themselves		
				HIDE.notifyLoadingComplete(name);
			}
			);
			
			HIDE.readFile(name, "templates/index.html", function (data:String):Void
			{
				indexPageCode = data;
			}
			);
		}
		);
	}
	
	private static function createCSharpProject(data:Dynamic):Void 
	{
		createHaxeProject(data, Project.CSHARP);
	}
	
	private static function createJavaProject(data:Dynamic):Void
	{
		createHaxeProject(data, Project.JAVA);
	}
	
	private static function createCppProject(data:Dynamic):Void
	{
		createHaxeProject(data, Project.CPP);
	}
	
	private static function createPhpProject(data:Dynamic):Void
	{
		createHaxeProject(data, Project.PHP);
	}
	
	private static function createNekoProject(data:Dynamic):Void
	{
		createHaxeProject(data, Project.NEKO);
	}
	
	private static function createFlashProject(data:Dynamic):Void
	{
		createHaxeProject(data, Project.FLASH);
	}
	
	private static function createJavaScriptProject(data:Dynamic):Void
	{
		createHaxeProject(data, Project.JAVASCRIPT);
	}
	
	private static function createHaxeProject(data:Dynamic, target:Int):Void
	{
		FileTools.createDirectoryRecursively(data.projectLocation, [data.projectName, "src"], function ():Void
		{
			var pathToProject:String  = data.projectLocation;
			
			if (data.createDirectory)
			{
				pathToProject = js.Node.path.join(pathToProject, data.projectName);
			}
			
			var pathToMain:String = pathToProject;
			
			pathToMain = js.Node.path.join(pathToMain, "src", "Main.hx");
			
			js.Node.fs.writeFile(pathToMain, code, function (error:js.Node.NodeErr):Void
			{
				if (error != null)
				{
					trace(error);
				}
				
				js.Node.fs.exists(pathToMain, function (exists:Bool):Void
				{
					if (exists)
					{
						TabManager.openFileInNewTab(pathToMain);
					}
					else 
					{
						trace(pathToMain + " file was not generated");
					}
				}
				);
			}
			);
			
			var project:Project = new Project();
			project.name = data.projectName;
			project.projectPackage = data.projectPackage;
			project.company = data.projectCompany;
			project.license = data.projectLicense;
			project.url = data.projectURL;
			project.type = Project.HAXE;
			project.target = target;
			project.path = pathToProject;
			project.buildActionCommand = ["haxe", "--connect", "6001", "--cwd", '"%path%"'].join(" ");
			
			var pathToBin:String = js.Node.path.join(pathToProject, "bin");
			
			js.Node.fs.mkdir(pathToBin, function (error):Void
			{
				var args:String = "-cp src\n-main Main\n"; 
			
				switch (project.target) 
				{
					case Project.FLASH:
						var pathToFile:String = "bin/" + project.name + ".swf";
						
						args += "-swf " + pathToFile + "\n";
						
						project.runActionType = Project.FILE;
						project.runActionText = pathToFile;
					case Project.JAVASCRIPT:
						var pathToFile:String = "bin/" +  project.name + ".js";
						
						args += "-js " + pathToFile + "\n";
						
						var updatedPageCode:String = StringTools.replace(indexPageCode, "::title::", project.name);
						updatedPageCode = StringTools.replace(updatedPageCode, "::script::", project.name + ".js");
						
						var pathToWebPage:String = js.Node.path.join(pathToBin, "index.html");
						
						js.Node.fs.writeFile(pathToWebPage, updatedPageCode, js.Node.NodeC.UTF8, function (error:js.Node.NodeErr):Void
						{
							
						}
						);
						
						project.runActionType = Project.FILE;
						project.runActionText = js.Node.path.join("bin", "index.html");
					case Project.NEKO:
						var pathToFile:String  = "bin/" + project.name + ".n";
						
						args += "-neko " + pathToFile +  "\n";
						
						project.runActionType = Project.COMMAND;
						project.runActionText = "neko " + js.Node.path.join(project.path, pathToFile);
					case Project.PHP:
						args += "-php " + "bin/" + project.name + ".php\n";
					case Project.CPP:
						var pathToFile:String = "bin/" + project.name + ".exe";
						args += "-cpp " + pathToFile + "\n";
						
						project.runActionType = Project.COMMAND;
						project.runActionText = js.Node.path.join(project.path, pathToFile);
					case Project.JAVA:
						args += "-java " + "bin/" + project.name + ".jar\n";
					case Project.CSHARP:
						args += "-cs " + "bin/" + project.name + ".exe\n";
						
					default:
						
				}
				
				args += "-debug\n -dce full";
				
				project.args = args.split("\n");
				
				var path:String = js.Node.path.join(pathToProject, "project.json");
				Browser.getLocalStorage().setItem("pathToLastProject", path);
				
				ProjectAccess.currentProject = project;
				
				ProjectAccess.save(function ()
				{
					FileTree.load(project.name, pathToProject);
				}
				);
				
				ProjectOptions.updateProjectOptions();
			});
		}
		);
	}
	
}