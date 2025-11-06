using System;

namespace __RootNamespace__.SharedKernel.Attributes;

/// <summary>
/// Atributo para marcar contextos de módulos para auto-registro
/// </summary>
[AttributeUsage(AttributeTargets.Class, AllowMultiple = false)]
public class ModuleContextAttribute : Attribute
{
    public string ModuleName { get; }
    public string[] Namespaces { get; }

    public ModuleContextAttribute(string moduleName, params string[] namespaces)
    {
        ModuleName = moduleName ?? throw new ArgumentNullException(nameof(moduleName));
        Namespaces = namespaces ?? throw new ArgumentNullException(nameof(namespaces));
    }
}

